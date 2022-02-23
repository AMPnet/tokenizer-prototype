// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./IAssetTransferable.sol";
import "../apx-protocol/IApxAssetsRegistry.sol";
import "../tokens/erc20/ERC20.sol";
import "../tokens/erc20/IToken.sol";
import "../shared/IIssuerCommon.sol";
import "../shared/ICampaignCommon.sol";
import "../shared/Structs.sol";

contract AssetTransferable is IAssetTransferable, ERC20 {
    using SafeERC20 for IERC20;

    //------------------------
    //  CONSTANTS
    //------------------------
    uint256 constant public override priceDecimalsPrecision = 10 ** 4;

    //----------------------
    //  STATE
    //------------------------
    Structs.AssetTransferableState private state;
    Structs.InfoEntry[] private infoHistory;
    Structs.WalletRecord[] private approvedCampaigns;
    Structs.TokenSaleInfo[] private sellHistory;
    mapping (address => uint256) public approvedCampaignsMap;
    mapping (address => Structs.TokenSaleInfo) public successfulTokenSalesMap;
    mapping (address => uint256) public liquidationClaimsMap;

    //------------------------
    //  EVENTS
    //------------------------
    event ChangeOwnership(address caller, address newOwner, uint256 timestamp);
    event SetInfo(string info, address setter, uint256 timestamp);
    event SetWhitelistRequiredForTransfer(address caller, bool whitelistRequiredForTransfer, uint256 timestamp);
    event SetWhitelistRequiredForRevenueClaim(address caller, bool whitelistRequired, uint256 timestamp);
    event SetApprovedByIssuer(address caller, bool approvedByIssuer, uint256 timestamp);
    event CampaignWhitelist(address approver, address wallet, bool whitelisted, uint256 timestamp);
    event SetIssuerStatus(address approver, bool status, uint256 timestamp);
    event FinalizeSale(address campaign, uint256 tokenAmount, uint256 tokenValue, uint256 timestamp);
    event Liquidated(address liquidator, uint256 liquidationFunds, uint256 timestamp);
    event ClaimLiquidationShare(address indexed investor, uint256 amount,  uint256 timestamp);

    //------------------------
    //  CONSTRUCTOR
    //------------------------
    constructor(
        Structs.AssetTransferableConstructorParams memory params
    ) ERC20(params.name, params.symbol) {
        require(params.owner != address(0), "AssetTransferable: Invalid owner provided");
        require(params.issuer != address(0), "AssetTransferable: Invalid issuer provided");
        require(params.initialTokenSupply > 0, "AssetTransferable: Initial token supply can't be 0");
        infoHistory.push(Structs.InfoEntry(
            params.info,
            block.timestamp
        ));
        bool assetApprovedByIssuer = (IIssuerCommon(params.issuer).commonState().owner == params.owner);
        address contractAddress = address(this);
        state = Structs.AssetTransferableState(
            params.flavor,
            params.version,
            contractAddress,
            params.owner,
            params.initialTokenSupply,
            params.whitelistRequiredForRevenueClaim,
            params.whitelistRequiredForLiquidationClaim,
            assetApprovedByIssuer,
            params.issuer,
            params.apxRegistry,
            params.info,
            params.name,
            params.symbol,
            0, 0, 0,
            false,
            0, 0, 0
        );
        _mint(params.owner, params.initialTokenSupply);
    }

    //------------------------
    //  MODIFIERS
    //------------------------
    modifier ownerOnly() {
        require(
            msg.sender == state.owner,
            "AssetTransferable: Only asset creator can make this action."
        );
        _;
    }

    modifier notLiquidated() {
        require(!state.liquidated, "AssetTransferable: Action forbidden, asset liquidated.");
        _;
    }

    //----------------------------------
    //  IAssetTransferable IMPL - Write
    //----------------------------------
    function approveCampaign(address campaign) external override ownerOnly notLiquidated {
        _setCampaignState(campaign, true);
        emit CampaignWhitelist(msg.sender, campaign, true, block.timestamp);
    }

    function suspendCampaign(address campaign) external override ownerOnly notLiquidated {
        _setCampaignState(campaign, false);
        emit CampaignWhitelist(msg.sender, campaign, false, block.timestamp);
    }

    function changeOwnership(address newOwner) external override ownerOnly {
        state.owner = newOwner;
        emit ChangeOwnership(msg.sender, newOwner, block.timestamp);
    }

    function setInfo(string memory info) external override ownerOnly {
        infoHistory.push(Structs.InfoEntry(
            info,
            block.timestamp
        ));
        state.info = info;
        emit SetInfo(info, msg.sender, block.timestamp);
    }

    function setWhitelistRequiredForRevenueClaim(bool whitelistRequired) external override ownerOnly {
        state.whitelistRequiredForRevenueClaim = whitelistRequired;
        emit SetWhitelistRequiredForRevenueClaim(msg.sender, whitelistRequired, block.timestamp);
    }

    function setWhitelistRequiredForLiquidationClaim(bool whitelistRequired) external override ownerOnly {
        state.whitelistRequiredForLiquidationClaim = whitelistRequired;
        emit SetWhitelistRequiredForTransfer(msg.sender, whitelistRequired, block.timestamp);
    }

    function setIssuerStatus(bool status) external override {
        require(
            msg.sender == _issuer().commonState().owner,
            "AssetTransferable: Only issuer owner can make this action." 
        );
        state.assetApprovedByIssuer = status;
        emit SetIssuerStatus(msg.sender, status, block.timestamp);
    }
    
    function finalizeSale() external override notLiquidated {
        address campaign = msg.sender;
        require(_campaignWhitelisted(campaign), "AssetTransferable: Campaign not approved.");
        Structs.CampaignCommonState memory campaignState = ICampaignCommon(campaign).commonState();
        require(campaignState.finalized, "AssetTransferable: Campaign not finalized");
        uint256 tokenValue = campaignState.fundsRaised;
        uint256 tokenAmount = campaignState.tokensSold;
        uint256 tokenPrice = campaignState.pricePerToken;
        require(
            tokenAmount > 0 && balanceOf(campaign) >= tokenAmount,
            "AssetTransferable: Campaign has signalled the sale finalization but campaign tokens are not present"
        );
        require(
            tokenValue > 0 && _stablecoin().balanceOf(campaign) >= tokenValue,
            "AssetTransferable: Campaign has signalled the sale finalization but raised funds are not present"
        );
        state.totalAmountRaised += tokenValue;
        state.totalTokensSold += tokenAmount;
        Structs.TokenSaleInfo memory tokenSaleInfo = Structs.TokenSaleInfo(
            campaign, tokenAmount, tokenValue, block.timestamp
        );
        sellHistory.push(tokenSaleInfo);
        successfulTokenSalesMap[campaign] = tokenSaleInfo;
        if (tokenPrice > state.highestTokenSellPrice) { state.highestTokenSellPrice = tokenPrice; }
        emit FinalizeSale(
            msg.sender,
            tokenAmount,
            tokenValue,
            block.timestamp
        );
    }

    function liquidate() external override notLiquidated ownerOnly {
        IApxAssetsRegistry apxRegistry = IApxAssetsRegistry(state.apxRegistry);
        Structs.AssetRecord memory assetRecord = apxRegistry.getMirrored(address(this));
        require(assetRecord.exists, "AssetTransferable: Not registered in Apx Registry");
        require(assetRecord.state, "AssetTransferable: Asset blocked in Apx Registry");
        require(assetRecord.mirroredToken == address(this), "AssetTransferable: Invalid mirrored asset record");
        require(block.timestamp <= assetRecord.priceValidUntil, "AssetTransferable: Price expired");
        uint256 liquidationPrice = 
            (state.highestTokenSellPrice > assetRecord.price) ? state.highestTokenSellPrice : assetRecord.price;
        uint256 liquidatorApprovedTokenAmount = this.allowance(msg.sender, address(this));
        uint256 liquidatorApprovedTokenValue = _tokenValue(liquidatorApprovedTokenAmount, liquidationPrice);
        if (liquidatorApprovedTokenValue > 0) {
            liquidationClaimsMap[msg.sender] += liquidatorApprovedTokenValue;
            state.liquidationFundsClaimed += liquidatorApprovedTokenValue;
            this.transferFrom(msg.sender, address(this), liquidatorApprovedTokenAmount);
        }
        uint256 liquidationFundsTotal = _tokenValue(totalSupply(), liquidationPrice);
        uint256 liquidationFundsToPull = liquidationFundsTotal - liquidatorApprovedTokenValue;
        if (liquidationFundsToPull > 0) {
            _stablecoin().safeTransferFrom(msg.sender, address(this), liquidationFundsToPull);
        }
        state.liquidated = true;
        state.liquidationTimestamp = block.timestamp;
        state.liquidationFundsTotal = liquidationFundsTotal;
        emit Liquidated(msg.sender, liquidationFundsTotal, block.timestamp);
    }

    function claimLiquidationShare(address investor) external override {
        require(state.liquidated, "AssetTransferable: not liquidated");
        require(
            !state.whitelistRequiredForLiquidationClaim ||
            _issuer().isWalletApproved(investor),
            "AssetTransferable: wallet must be whitelisted before claiming liquidation share."
        );
        uint256 approvedAmount = allowance(investor, address(this));
        require(approvedAmount > 0, "AssetTransferable: no tokens approved for claiming liquidation share");
        uint256 liquidationFundsShare = approvedAmount * state.liquidationFundsTotal / totalSupply();
        require(liquidationFundsShare > 0, "AssetTransferable: no liquidation funds to claim");
        liquidationClaimsMap[investor] += liquidationFundsShare;
        state.liquidationFundsClaimed += liquidationFundsShare;
        _stablecoin().safeTransfer(investor, liquidationFundsShare);
        this.transferFrom(investor, address(this), approvedAmount);
        emit ClaimLiquidationShare(investor, liquidationFundsShare, block.timestamp);
    }

    function migrateApxRegistry(address newRegistry) external override notLiquidated {
        require(msg.sender == state.apxRegistry, "AssetTransferable: Only apxRegistry can call this function.");
        state.apxRegistry = newRegistry;
    }

    //---------------------------------
    //  IAssetTransferable IMPL - Read
    //---------------------------------
    function flavor() external view override returns (string memory) { return state.flavor; }

    function version() external view override returns (string memory) { return state.version; }
    
    function commonState() external view override returns (Structs.AssetCommonState memory) {
        return Structs.AssetCommonState(
            state.flavor,
            state.version,
            state.contractAddress,
            state.owner,
            state.info,
            state.name,
            state.symbol,
            totalSupply(),
            decimals(),
            state.issuer
        );
    }

    function getState() external view override returns (Structs.AssetTransferableState memory) {
        return state;
    }

    function getInfoHistory() external view override returns (Structs.InfoEntry[] memory) {
        return infoHistory;
    }

    function getCampaignRecords() external view override returns (Structs.WalletRecord[] memory) {
        return approvedCampaigns;
    }

    function getSellHistory() external view override returns (Structs.TokenSaleInfo[] memory) {
        return sellHistory;
    }

    //------------------------
    //  ERC20 OVERRIDES
    //------------------------
    function balanceOf(address account) public view override returns (uint256) {
        if (state.liquidated) { return (account == state.owner) ? totalSupply() : 0; }
        return super.balanceOf(account);
    }

    //------------------------
    //  Helpers
    //------------------------
    function _stablecoin() private view returns (IERC20) {
        return IERC20(_stablecoin_address());
    }

    function _stablecoin_address() private view returns (address) {
        return _issuer().commonState().stablecoin;
    }

    function _issuer() private view returns (IIssuerCommon) {
        return IIssuerCommon(state.issuer);
    }

    function _setCampaignState(address wallet, bool whitelisted) private {
        if (_campaignExists(wallet)) {
            approvedCampaigns[approvedCampaignsMap[wallet]].whitelisted = whitelisted;
        } else {
            approvedCampaigns.push(Structs.WalletRecord(wallet, whitelisted));
            approvedCampaignsMap[wallet] = approvedCampaigns.length - 1;
        }
    }

    function _campaignWhitelisted(address wallet) private view returns (bool) {
        if (ICampaignCommon(wallet).commonState().owner == state.owner) {
            return true;
        }
        return _campaignExists(wallet) && approvedCampaigns[approvedCampaignsMap[wallet]].whitelisted;
    }

    function _campaignExists(address wallet) private view returns (bool) {
        uint256 index = approvedCampaignsMap[wallet];
        if (approvedCampaigns.length == 0) { return false; }
        if (index >= approvedCampaigns.length) { return false; }
        if (approvedCampaigns[index].wallet != wallet) { return false; }
        return true;
    }

    function _tokenValue(uint256 amount, uint256 price) private view returns (uint256) {
        return amount
                * price
                * _stablecoin_decimals_precision()
                / (_asset_decimals_precision() * priceDecimalsPrecision);
    }

    function _stablecoin_decimals_precision() private view returns (uint256) {
        return 10 ** IToken(_stablecoin_address()).decimals();
    }

    function _asset_decimals_precision() private view returns (uint256) {
        return 10 ** decimals();
    }

}

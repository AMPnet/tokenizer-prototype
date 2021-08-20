// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { SafeERC20, ChildMintableERC20, IERC20} from "../tokens/matic/ChildMintableERC20.sol";
import "./IAssetTransferable.sol";
import "../issuer/IIssuer.sol";
import "../managers/crowdfunding-softcap/ICfManagerSoftcap.sol";
import "../tokens/apx-protocol/IMirroredToken.sol";
import "../tokens/IToken.sol";
import "../shared/Structs.sol";

contract AssetTransferable is IAssetTransferable, ChildMintableERC20 {
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
    Structs.TokenPriceRecord public tokenPriceRecord;
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
        uint256 id,
        address owner,
        address issuer,
        string memory ansName,
        uint256 ansId,
        uint256 initialTokenSupply,
        bool whitelistRequiredForRevenueClaim,
        bool whitelistRequiredForLiquidationClaim,
        string memory name,
        string memory symbol,
        string memory info,
        address childChainManager
    ) ChildMintableERC20(name, symbol, childChainManager)
    {
        require(owner != address(0), "Asset: Invalid owner provided");
        require(issuer != address(0), "Asset: Invalid issuer provided");
        require(initialTokenSupply > 0, "Asset: Initial token supply can't be 0");
        require(childChainManager != address(0), "MirroredToken: invalid child chain manager address");
        infoHistory.push(Structs.InfoEntry(
            info,
            block.timestamp
        ));
        bool assetApprovedByIssuer = (IIssuer(issuer).getState().owner == owner);
        address contractAddress = address(this);
        state = Structs.AssetTransferableState(
            id,
            contractAddress,
            ansName,
            ansId,
            msg.sender,
            owner,
            initialTokenSupply,
            whitelistRequiredForRevenueClaim,
            whitelistRequiredForLiquidationClaim,
            assetApprovedByIssuer,
            issuer,
            info,
            name,
            symbol,
            0, 0, 0,
            false,
            0, 0, 0
        );
        _mint(owner, initialTokenSupply);
    }

    //------------------------
    //  MODIFIERS
    //------------------------
    modifier ownerOnly() {
        require(
            msg.sender == state.owner,
            "Asset: Only asset creator can make this action."
        );
        _;
    }

    modifier notLiquidated() {
        require(!state.liquidated, "Asset: Action forbidden, asset liquidated.");
        _;
    }

    //------------------------
    //  IAsset IMPL - Write
    //------------------------
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
            msg.sender == IIssuer(state.issuer).getState().owner,
            "Asset: Only issuer owner can make this action." 
        );
        state.assetApprovedByIssuer = status;
        emit SetIssuerStatus(msg.sender, status, block.timestamp);
    }
    
    function finalizeSale() external override notLiquidated {
        address campaign = msg.sender;
        require(_campaignWhitelisted(campaign), "Asset: Campaign not approved.");
        Structs.CfManagerSoftcapState memory campaignState = ICfManagerSoftcap(campaign).getState();
        require(campaignState.finalized, "Asset: Campaign not finalized");
        uint256 tokenValue = campaignState.totalFundsRaised;
        uint256 tokenAmount = campaignState.totalTokensSold;
        uint256 tokenPrice = campaignState.tokenPrice;
        require(
            tokenAmount > 0 && balanceOf(campaign) >= tokenAmount,
            "Asset: Campaign has signalled the sale finalization but campaign tokens are not present"
        );
        require(
            tokenValue > 0 && _stablecoin().balanceOf(campaign) >= tokenValue,
            "Asset: Campaign has signalled the sale finalization but raised funds are not present"
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
        uint256 liquidationFunds = _tokenValue(state.totalTokensSold, tokenPriceRecord.price);
        require(liquidationFunds > 0, "AssetTransferable: Liquidation funds are zero.");
        require(tokenPriceRecord.validUntilTimestamp <= block.timestamp, "AssetTransferable: Price expired.");
        _stablecoin().safeTransferFrom(msg.sender, address(this), liquidationFunds);
        state.liquidated = true;
        state.liquidationTimestamp = block.timestamp;
        state.liquidationFundsTotal = liquidationFunds;
        emit Liquidated(msg.sender, liquidationFunds, block.timestamp);
    }

    function claimLiquidationShare(address investor) external override {
        require(state.liquidated, "Asset: not liquidated");
        require(
            !state.whitelistRequiredForLiquidationClaim ||
            _issuer().isWalletApproved(investor),
            "Asset: wallet must be whitelisted before claiming liquidation share."
        );
        uint256 approvedAmount = allowance(investor, address(this));
        require(approvedAmount > 0, "Asset: no tokens approved for claiming liquidation share");
        uint256 liquidationFundsShare = approvedAmount * state.liquidationFundsTotal / totalSupply();
        require(liquidationFundsShare > 0, "Asset: no liquidation funds to claim");
        _stablecoin().safeTransfer(investor, liquidationFundsShare);
        transferFrom(investor, address(this), approvedAmount);
        liquidationClaimsMap[investor] += liquidationFundsShare;
        state.liquidationFundsClaimed += liquidationFundsShare;
        emit ClaimLiquidationShare(investor, liquidationFundsShare, block.timestamp);
    }

    function snapshot() external override notLiquidated returns (uint256) {
        return _snapshot();
    }

    //------------------------
    //  IAsset IMPL - Read
    //------------------------
    function totalShares() external view override returns (uint256) {
        return totalSupply();
    }

    function getDecimals() external view override returns (uint256) {
        return uint256(decimals());
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
        return _issuer().getState().stablecoin;
    }

    function _issuer() private view returns (IIssuer) {
        return IIssuer(state.issuer);
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
        if (ICfManagerSoftcap(wallet).getState().owner == state.owner) {
            return true;
        }
        if (_campaignExists(wallet)) { 
            return approvedCampaigns[approvedCampaignsMap[wallet]].whitelisted;
        }
        return false;
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
        return IToken(_stablecoin_address()).decimals();
    }

    function _asset_decimals_precision() private view returns (uint256) {
        return 10 ** decimals();
    }

}

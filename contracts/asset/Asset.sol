// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./IAsset.sol";
import "../apx-protocol/IMirroredToken.sol";
import "../apx-protocol/IApxAssetsRegistry.sol";
import "../tokens/erc20/IToken.sol";
import "../tokens/erc20/ERC20.sol";
import "../shared/IIssuerCommon.sol";
import "../shared/ICampaignCommon.sol";
import "../shared/Structs.sol";

contract Asset is IAsset, ERC20 {
    using SafeERC20 for IERC20;

    //------------------------
    //  CONSTANTS
    //------------------------
    uint256 constant public override priceDecimalsPrecision = 10 ** 4;

    //-----------------------
    //  STATE
    //-----------------------
    Structs.AssetState private state;
    Structs.InfoEntry[] private infoHistory;
    Structs.TokenSaleInfo[] private sellHistory;
    mapping (address => Structs.WalletRecord) public approvedCampaignsMap;
    mapping (address => Structs.TokenSaleInfo) public successfulTokenSalesMap;
    mapping (address => uint256) public liquidationClaimsMap;
    mapping (address => uint256) public locked;

    //------------------------
    //  EVENTS
    //------------------------
    event SetInfo(string info, address setter, uint256 timestamp);
    event FinalizeSale(address campaign, uint256 tokenAmount, uint256 tokenValue, uint256 timestamp);
    event Liquidated(address liquidator, uint256 liquidationFunds, uint256 timestamp);
    event ClaimLiquidationShare(address indexed investor,uint256 amount, uint256 timestamp);
    event LockTokens(address indexed wallet, address mirroredToken, uint256 amount, uint256 timestamp);
    event UnlockTokens(address indexed wallet, address mirroredToken, uint256 amount, uint256 timestamp);

    //------------------------
    //  CONSTRUCTOR
    //------------------------
    constructor(Structs.AssetConstructorParams memory params) ERC20(params.name, params.symbol)
    {
        require(params.owner != address(0), "Asset: Invalid owner provided");
        require(params.issuer != address(0), "Asset: Invalid issuer provided");
        require(params.initialTokenSupply > 0, "Asset: Initial token supply can't be 0");
        infoHistory.push(Structs.InfoEntry(
            params.info,
            block.timestamp
        ));
        bool assetApprovedByIssuer = (IIssuerCommon(params.issuer).commonState().owner == params.owner);
        address contractAddress = address(this);
        state = Structs.AssetState(
            params.flavor,
            params.version,
            contractAddress,
            params.owner,
            params.initialTokenSupply,
            params.transferable,
            params.whitelistRequiredForRevenueClaim,
            params.whitelistRequiredForLiquidationClaim,
            assetApprovedByIssuer,
            params.issuer,
            params.apxRegistry,
            params.info,
            params.name,
            params.symbol,
            0, 0, 0, 0, 0,
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
            "Asset: Only asset creator can make this action."
        );
        _;
    }

    modifier transferAllowed(address from, address to) {
        IIssuerCommon issuer = _issuer();
        require(
            state.transferable ||
            (to == state.owner) ||
            (from == address(this) && issuer.isWalletApproved(to)) ||
            (to == address(this) && issuer.isWalletApproved(from)) ||
            (from == state.owner && _campaignWhitelisted(to)) ||
            (_campaignWhitelisted(from) && issuer.isWalletApproved(to)),
            "Asset: Not transferable. Only token mirroring is allowed."
        );
        _;
    }

    //------------------------
    //  IAsset IMPL - Write
    //------------------------
    function freezeTransfer() external override ownerOnly { state.transferable = false; }
    
    function lockTokens(uint256 amount) external override {
        Structs.AssetRecord memory assetRecord = 
            IApxAssetsRegistry(state.apxRegistry).getMirroredFromOriginal(address(this));
        require(assetRecord.exists, "Asset: Mirrored APX token does not exist.");
        require(assetRecord.state, "Asset: Mirrored APX token is blacklisted.");
        require(
            assetRecord.originalToken == address(this),
            "Asset: Mirrored APX token is not connected to the original."
        );
        require(assetRecord.mirroredToken != address(0), "Asset: Invalid mirrored token bridged to the original.");
        require(this.allowance(msg.sender, address(this)) >= amount, "Asset: Missing allowance for token lock.");
        
        address mirroredToken = assetRecord.mirroredToken;
        state.totalTokensLocked += amount;
        locked[mirroredToken] += amount;

        this.transferFrom(msg.sender, address(this), amount); 
        IMirroredToken(mirroredToken).mintMirrored(msg.sender, amount);
        emit LockTokens(msg.sender, mirroredToken, amount, block.timestamp);
    }

    function unlockTokens(address wallet, uint256 amount) external override {
        require(locked[msg.sender] >= amount, "Asset: insufficent amount of locked tokens");
        this.transfer(wallet, amount);
        state.totalTokensLocked -= amount;
        locked[msg.sender] -= amount;
        emit UnlockTokens(wallet, msg.sender, amount, block.timestamp);
    }

    function setCampaignState(address campaign, bool approved) external override ownerOnly {
        bool campaignExists = approvedCampaignsMap[campaign].wallet == campaign;
        if (campaignExists) {
            approvedCampaignsMap[campaign].whitelisted = approved;
        } else {
            approvedCampaignsMap[campaign] = Structs.WalletRecord(campaign, approved);
        }
    }

    function changeOwnership(address newOwner) external override ownerOnly {
        state.owner = newOwner;
        if (newOwner == _issuer().commonState().owner) { state.assetApprovedByIssuer = true; }
    }

    function setInfo(string memory info) external override ownerOnly {
        infoHistory.push(Structs.InfoEntry(
            info,
            block.timestamp
        ));
        state.info = info;
        emit SetInfo(info, msg.sender, block.timestamp);
    }

    function setWhitelistFlags(
        bool whitelistRequiredForRevenueClaim,
        bool whitelistRequiredForLiquidationClaim
    ) external override ownerOnly {
        state.whitelistRequiredForRevenueClaim = whitelistRequiredForRevenueClaim;
        state.whitelistRequiredForLiquidationClaim = whitelistRequiredForLiquidationClaim;
    }
    
    function setIssuerStatus(bool status) external override {
        require(
            msg.sender == _issuer().commonState().owner,
            "Asset: Only issuer owner can make this action." 
        );
        state.assetApprovedByIssuer = status;
    }
    
    function finalizeSale() external override {
        require(!state.liquidated, "Asset: Action forbidden, asset liquidated.");
        address campaign = msg.sender;
        require(_campaignWhitelisted(campaign), "Asset: Campaign not approved.");
        Structs.CampaignCommonState memory campaignState = ICampaignCommon(campaign).commonState();
        require(campaignState.finalized, "Asset: Campaign not finalized");
        uint256 tokenValue = campaignState.fundsRaised;
        uint256 tokenAmount = campaignState.tokensSold;
        uint256 tokenPrice = campaignState.pricePerToken;
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

    function liquidate() external override ownerOnly {
        require(!state.liquidated, "Asset: Action forbidden, asset liquidated.");
        uint256 liquidationPrice;
        if (state.totalTokensLocked > 0) {
            IApxAssetsRegistry apxRegistry = IApxAssetsRegistry(state.apxRegistry);        
            Structs.AssetRecord memory assetRecord = apxRegistry.getMirroredFromOriginal(address(this));
            require(assetRecord.state, "Asset: Asset blocked in Apx Registry");
            require(assetRecord.originalToken == address(this), "Asset: Invalid mirrored asset record");
            require(block.timestamp <= assetRecord.priceValidUntil, "Asset: Price expired");
            require(state.totalTokensLocked == assetRecord.capturedSupply, "Asset: MirroredToken supply inconsistent");
            liquidationPrice = 
                (state.highestTokenSellPrice > assetRecord.price) ? state.highestTokenSellPrice : assetRecord.price;
        } else {
            liquidationPrice = state.highestTokenSellPrice;
        }

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
        require(state.liquidated, "Asset: not liquidated");
        require(
            !state.whitelistRequiredForLiquidationClaim ||
            _issuer().isWalletApproved(investor),
            "Asset: wallet must be whitelisted before claiming liquidation share."
        );
        uint256 approvedAmount = this.allowance(investor, address(this));
        require(approvedAmount > 0, "Asset: no tokens approved for claiming liquidation share");
        uint256 liquidationFundsShare = approvedAmount * state.liquidationFundsTotal / totalSupply();
        require(liquidationFundsShare > 0, "Asset: no liquidation funds to claim");
        _stablecoin().safeTransfer(investor, liquidationFundsShare);
        this.transferFrom(investor, address(this), approvedAmount);
        liquidationClaimsMap[investor] += liquidationFundsShare;
        state.liquidationFundsClaimed += liquidationFundsShare;
        emit ClaimLiquidationShare(investor, liquidationFundsShare, block.timestamp);
    }
    
    function migrateApxRegistry(address newRegistry) external override {
        require(msg.sender == state.apxRegistry, "Asset: Only apxRegistry can call this function.");
        state.apxRegistry = newRegistry;
    }

    //------------------------
    //  IAsset IMPL - Read
    //------------------------
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
    
    function getState() external view override returns (Structs.AssetState memory) {
        return state;
    }

    function getInfoHistory() external view override returns (Structs.InfoEntry[] memory) {
        return infoHistory;
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

    function transfer(address recipient, uint256 amount)
        public
        override
        transferAllowed(msg.sender, recipient)
        returns (bool)
    {
        return super.transfer(recipient, amount);
    }

    function transferFrom(address sender, address recipient, uint256 amount)
        public
        override
        transferAllowed(sender, recipient)
        returns (bool)
    {
        return super.transferFrom(sender, recipient, amount);
    }

    //------------------------
    //  Helpers
    //------------------------
    function _issuer() private view returns (IIssuerCommon) {
        return IIssuerCommon(state.issuer);
    }

    function _stablecoin() private view returns (IERC20) {
        return IERC20(_stablecoin_address());
    }

    function _stablecoin_address() private view returns (address) {
        return _issuer().commonState().stablecoin;
    }

    function _campaignWhitelisted(address campaignAddress) private view returns (bool) {
        if (ICampaignCommon(campaignAddress).commonState().owner == state.owner) {
            return true;
        }
        Structs.WalletRecord memory campaignRecord = approvedCampaignsMap[campaignAddress];
        return (campaignRecord.wallet == campaignAddress && campaignRecord.whitelisted);
    }

    function _tokenValue(uint256 amount, uint256 price) private view returns (uint256) {
        return amount
                * price
                * (10 ** IToken(_stablecoin_address()).decimals())
                / ((10 ** decimals()) * priceDecimalsPrecision);
    }

}

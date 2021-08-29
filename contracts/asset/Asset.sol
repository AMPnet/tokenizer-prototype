// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../tokens/erc20/ERC20.sol";
import "../tokens/erc20/ERC20Snapshot.sol";
import "./IAsset.sol";
import "../issuer/IIssuer.sol";
import "../managers/crowdfunding-softcap/ICfManagerSoftcap.sol";
import "../apx-protocol/IMirroredToken.sol";
import "../tokens/erc20/IToken.sol";
import "../shared/Structs.sol";

contract Asset is IAsset, ERC20Snapshot {
    using SafeERC20 for IERC20;

    //------------------------
    //  CONSTANTS
    //------------------------
    uint256 constant public override priceDecimalsPrecision = 10 ** 4;

    //----------------------
    //  STATE
    //------------------------
    Structs.AssetState private state;
    Structs.InfoEntry[] private infoHistory;
    Structs.WalletRecord[] private approvedCampaigns;
    Structs.TokenSaleInfo[] private sellHistory;
    mapping (address => uint256) public approvedCampaignsMap;
    mapping (address => Structs.TokenSaleInfo) public successfulTokenSalesMap;
    mapping (address => uint256) public liquidationClaimsMap;
    mapping (address => uint256) public locked;

    //------------------------
    //  EVENTS
    //------------------------
    event ChangeOwnership(address caller, address newOwner, uint256 timestamp);
    event SetInfo(string info, address setter, uint256 timestamp);
    event SetWhitelistRequiredForRevenueClaim(address caller, bool whitelistRequired, uint256 timestamp);
    event SetWhitelistRequiredForLiquidationClaim(address caller, bool whitelistRequired, uint256 timestamp);
    event SetApprovedByIssuer(address caller, bool approvedByIssuer, uint256 timestamp);
    event CampaignWhitelist(address approver, address wallet, bool whitelisted, uint256 timestamp);
    event SetIssuerStatus(address approver, bool status, uint256 timestamp);
    event FinalizeSale(address campaign, uint256 tokenAmount, uint256 tokenValue, uint256 timestamp);
    event Liquidated(address liquidator, uint256 liquidationFunds, uint256 liquidatedTokensAmount, uint256 timestamp);
    event LiquidateMirrored(
        address liquidator,
        uint256 liquidationFunds,
        uint256 liquidatedTokensAmount,
        address mirroredToken,
        uint256 timestamp
    );
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
        bool assetApprovedByIssuer = (IIssuer(params.issuer).getState().owner == params.owner);
        address contractAddress = address(this);
        state = Structs.AssetState(
            params.id,
            contractAddress,
            params.ansName,
            params.ansId,
            msg.sender,
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
            0, 0, 0, 0, 0,
            false,
            0, 0, 0
        );
        _mint(params.owner, params.initialTokenSupply);
    }

    //------------------------
    //  MODIFIERS
    //------------------------
    modifier walletApproved(address wallet) {
        require(
            wallet == state.owner || 
            IIssuer(state.issuer).isWalletApproved(wallet) ||
            _campaignWhitelisted(wallet),
            "Asset: This functionality is not allowed. Wallet is not whitelisted."
        );
        _;
    }

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

    modifier transferAllowed(address from, address to) {
        IIssuer issuer = _issuer();
        require(
            ((from == address(this) || _campaignWhitelisted(from)) && issuer.isWalletApproved(to)) ||
            ((to == address(this) || _campaignWhitelisted(to)) && issuer.isWalletApproved(from)),
            "Asset: Not transferable. Only token mirroring is allowed."
        );
        _;
    }

    //------------------------
    //  IAsset IMPL - Write
    //------------------------
    function lockTokens(address mirroredToken, uint256 amount) external override notLiquidated {
        require(allowance(msg.sender, address(this)) >= amount, "Asset: Missing allowance for token lock");
        transferFrom(msg.sender, address(this), amount);
        IMirroredToken(mirroredToken).mintMirrored(msg.sender, amount);
        state.totalTokensLocked += amount;
        locked[mirroredToken] += amount;
        emit LockTokens(msg.sender, mirroredToken, amount, block.timestamp);
    }

    function unlockTokens(address wallet, uint256 amount) external override notLiquidated {
        require(locked[msg.sender] >= amount, "Asset: insufficent amount of locked tokens");
        transfer(wallet, amount);
        state.totalTokensLocked -= amount;
        locked[msg.sender] -= amount;
        emit UnlockTokens(wallet, msg.sender, amount, block.timestamp);
    }

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
        emit SetWhitelistRequiredForLiquidationClaim(msg.sender, whitelistRequired, block.timestamp);
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

    function liquidate(address[] memory mirroredTokens) external override notLiquidated ownerOnly {
        // Liquidate mirrored tokens first (if any provided)
        for (uint i = 0; i < mirroredTokens.length; i++) { liquidateMirrored(mirroredTokens[i]); }
        require(
            state.totalTokensLocked == state.totalTokensLockedAndLiquidated,
            "Asset: Can't liquidate original token. Liquidate mirrored tokens!"
        );
        // If mirrored liquidated, proceed with liquidating the original asset (this)
        uint256 activeSupply = totalSupply() - state.totalTokensLocked;
        uint256 liquidationFunds = _tokenValue(activeSupply, state.highestTokenSellPrice);
        if (liquidationFunds > 0) {
            _stablecoin().safeTransferFrom(msg.sender, address(this), liquidationFunds);
        }
        state.liquidated = true;
        state.liquidationFundsTotal = liquidationFunds;
        state.liquidationTimestamp = block.timestamp;
        emit Liquidated(msg.sender, liquidationFunds, activeSupply, block.timestamp);
    }

    function liquidateMirrored(address mirroredTokenAddress) public override notLiquidated ownerOnly {
        require(mirroredTokenAddress != address(0), "Asset: Invalid mirrored token address");
        require(locked[mirroredTokenAddress] > 0, "Asset: No tokens mirrored on the provided token address");
        IMirroredToken mirroredToken = IMirroredToken(mirroredTokenAddress);
        uint256 liquidationFunds = mirroredToken.lastKnownMarketCap();
        _stablecoin().safeTransferFrom(msg.sender, mirroredTokenAddress, mirroredToken.lastKnownMarketCap());
        uint256 liquidatedTokensAmount = mirroredToken.liquidate();
        require(
            liquidatedTokensAmount == locked[mirroredTokenAddress],
            "Asset: Liquidated tokens supply does not match the locked tokens supply."
        );
        state.totalTokensLockedAndLiquidated += liquidatedTokensAmount;
        locked[mirroredTokenAddress] = 0;
        emit LiquidateMirrored(
            msg.sender,
            liquidationFunds,
            liquidatedTokensAmount,
            mirroredTokenAddress,
            block.timestamp
        );
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

    function migrateApxRegistry(address newRegistry) external override {
        
    }

    //------------------------
    //  IAsset IMPL - Read
    //------------------------
    function getState() external view override returns (Structs.AssetState memory) {
        return state;
    }

    function getIssuerAddress() external view override returns (address) { return state.issuer; }

    function getAssetFactory() external view override returns (address) { return state.createdBy; }

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
    function _issuer() private view returns (IIssuer) {
        return IIssuer(state.issuer);
    }

    function _stablecoin() private view returns (IERC20) {
        return IERC20(_stablecoin_address());
    }

    function _stablecoin_address() private view returns (address) {
        return _issuer().getState().stablecoin;
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

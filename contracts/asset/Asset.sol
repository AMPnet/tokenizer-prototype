// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Snapshot.sol";
import "../asset/IAsset.sol";
import "../issuer/IIssuer.sol";
import "../managers/crowdfunding-softcap/ICfManagerSoftcap.sol";
import "../tokens/IMirroredToken.sol";
import "../shared/Structs.sol";

contract Asset is IAsset, ERC20Snapshot {
    using SafeERC20 for IERC20;

    //------------------------
    //  STATE
    //------------------------
    Structs.AssetState private state;
    Structs.InfoEntry[] private infoHistory;
    Structs.WalletRecord[] private approvedCampaigns;
    Structs.TokenSaleInfo[] private sellHistory;
    mapping (address => uint256) public approvedCampaignsMap;
    mapping (address => Structs.TokenSaleInfo) public successfulTokenSalesMap;
    mapping (address => mapping (address => uint256)) public liquidationClaimsMap;

    //------------------------
    //  EVENTS
    //------------------------
    event ChangeOwnership(address caller, address newOwner, uint256 timestamp);
    event SetInfo(string info, address setter, uint256 timestamp);
    event SetWhitelistRequiredForTransfer(address caller, bool whitelistRequiredForTransfer, uint256 timestamp);
    event SetApprovedByIssuer(address caller, bool approvedByIssuer, uint256 timestamp);
    event CampaignWhitelist(address approver, address wallet, bool whitelisted, uint256 timestamp);
    event SetIssuerStatus(address approver, bool status, uint256 timestamp);
    event FinalizeSale(address campaign, uint256 tokenAmount, uint256 tokenValue, uint256 timestamp);
    event Liquidated(address liquidator, uint256 liquidationFunds, uint256 liquidationSnapshotId, uint256 timestamp);
    event SetMirroredToken(address caller, address mirroredToken, uint256 timestamp);
    event ConvertFromMirrored(address indexed caller, address mirroredToken, uint256 amount, uint256 timestamp);
    event ClaimLiquidationShare(address indexed investor, address campaign, uint256 amount, uint256 timestamp);

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
        bool whitelistRequiredForTransfer,
        string memory name,
        string memory symbol,
        string memory info
    ) ERC20(name, symbol)
    {
        require(owner != address(0), "Asset: Invalid owner provided");
        require(issuer != address(0), "Asset: Invalid issuer provided");
        require(initialTokenSupply > 0, "Asset: Initial token supply can't be 0");
        infoHistory.push(Structs.InfoEntry(
            info,
            block.timestamp
        ));
        bool assetApprovedByIssuer = (IIssuer(issuer).getState().owner == owner);
        address contractAddress = address(this);
        state = Structs.AssetState(
            id,
            contractAddress,
            ansName,
            ansId,
            msg.sender,
            owner,
            address(0),
            initialTokenSupply,
            whitelistRequiredForTransfer,
            assetApprovedByIssuer,
            issuer,
            info,
            name,
            symbol,
            0, 0,
            false,
            0, 0, 0
        );
        _mint(owner, initialTokenSupply);
    }

    //------------------------
    //  MODIFIERS
    //------------------------
    modifier walletApproved(address wallet) {
        require(
            wallet == state.owner || 
            !state.whitelistRequiredForTransfer || 
            (
                state.whitelistRequiredForTransfer && 
                ( IIssuer(state.issuer).isWalletApproved(wallet) || _campaignWhitelisted(wallet) )
            ),
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

    //------------------------
    //  IAsset IMPL - Write
    //------------------------
    function approveCampaign(address campaign) external override ownerOnly {
        _setCampaignState(campaign, true);
        emit CampaignWhitelist(msg.sender, campaign, true, block.timestamp);
    }

    function suspendCampaign(address campaign) external override ownerOnly {
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

    function setWhitelistRequiredForTransfer(bool whitelistRequiredForTransfer) external override ownerOnly {
        state.whitelistRequiredForTransfer = whitelistRequiredForTransfer;
        emit SetWhitelistRequiredForTransfer(msg.sender, whitelistRequiredForTransfer, block.timestamp);
    }

    function setIssuerStatus(bool status) external override {
        require(
            msg.sender == IIssuer(state.issuer).getState().owner,
            "Asset: Only issuer owner can make this action." 
        );
        state.assetApprovedByIssuer = status;
        emit SetIssuerStatus(msg.sender, status, block.timestamp);
    }

    function setMirroredToken(address token) external override ownerOnly notLiquidated {
        if (state.mirroredToken != address(0)) {
            require(
                balanceOf(token) == 0,
                "Asset: can't update mirrored token; the existing one is still active and in circulation."
            );
        }
        state.mirroredToken = token;
        emit SetMirroredToken(msg.sender, token, block.timestamp);
    }

    function convertFromMirrored() external override notLiquidated {
        require(
            state.mirroredToken != address(0),
            "Asset: can't convert from mirrored token; Mirrored token was never initialized."
        );
        IERC20 mirroredToken = IERC20(state.mirroredToken);
        uint256 amount = mirroredToken.allowance(msg.sender, address(this));
        require(
            amount > 0,
            "Asset: can't convert from mirrored token; Missing approval."
        );
        mirroredToken.safeTransferFrom(msg.sender, address(this), amount);
        transfer(msg.sender, amount);
        emit ConvertFromMirrored(msg.sender, state.mirroredToken, amount, block.timestamp);
    }

    function finalizeSale(uint256 tokenAmount, uint256 tokenValue) external override notLiquidated {
        address campaign = msg.sender;
        require(_campaignWhitelisted(campaign), "Asset: Campaign not approved.");
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
        emit FinalizeSale(
            msg.sender,
            tokenAmount,
            tokenValue,
            block.timestamp
        );
    }

    function liquidate() external override notLiquidated ownerOnly {
        // Liquidate mirrored asset first (only if mirrored asset exists and some of the supply is actually mirrored)
        if (state.mirroredToken != address(0) && balanceOf(state.mirroredToken) > 0) {
            IMirroredToken mirroredToken = IMirroredToken(state.mirroredToken);
            uint256 mirroredLiquidationFunds = mirroredToken.lastKnownTokenValue();
            _stablecoin().safeTransferFrom(msg.sender, state.mirroredToken, mirroredLiquidationFunds);
            mirroredToken.liquidate();
        }
        // Liquidate the original asset (this)
        uint256 liquidationFunds = state.totalAmountRaised;
        if (liquidationFunds > 0) {
            _stablecoin().safeTransferFrom(msg.sender, address(this), liquidationFunds);
        }
        uint256 snapshotId = _snapshot();
        state.liquidated = true;
        state.liquidationTimestamp = block.timestamp;
        state.liquidationSnapshotId = snapshotId;
        emit Liquidated(msg.sender, liquidationFunds, snapshotId, block.timestamp);
    }

    function claimLiquidationShare(address campaign, address investor) external override {
        require(state.liquidated, "Asset: not liquidated");
        Structs.TokenSaleInfo memory tokenSaleInfo = successfulTokenSalesMap[campaign];
        require(
            tokenSaleInfo.cfManager != address(0),
            "Asset: invalid campaign address provided for claim liquidation share."
        );
        require(
            liquidationClaimsMap[campaign][investor] == 0,
            "Asset: investor has already claimed for given campaign."
        );
        uint256 investmentAmount = ICfManagerSoftcap(campaign).investments(investor);
        _stablecoin().transfer(investor, investmentAmount);
        liquidationClaimsMap[campaign][investor] = investmentAmount;
        state.liquidationFundsClaimed += investmentAmount;
        emit ClaimLiquidationShare(investor, campaign, investmentAmount, block.timestamp);
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

    function getState() external view override returns (Structs.AssetState memory) {
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

    function transfer(address recipient, uint256 amount)
        public
        override
        walletApproved(_msgSender())
        walletApproved(recipient)
        notLiquidated
        returns (bool)
    {
        return super.transfer(recipient, amount);
    }

    function approve(address spender, uint256 amount)
        public
        override
        walletApproved(_msgSender())
        walletApproved(spender)
        notLiquidated
        returns (bool)
    {
        return super.approve(spender, amount);
    }

    function transferFrom(address sender, address recipient, uint256 amount)
        public
        override
        walletApproved(sender)
        walletApproved(recipient)
        notLiquidated
        returns (bool)
    {
        return super.transferFrom(sender, recipient, amount);
    }

    function increaseAllowance(address spender, uint256 addedValue)
        public
        override
        walletApproved(_msgSender())
        walletApproved(spender)
        notLiquidated
        returns (bool)
    {
        return super.increaseAllowance(spender, addedValue);
    }

    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        override
        walletApproved(_msgSender())
        walletApproved(spender)
        notLiquidated
        returns (bool)
    {
        return super.decreaseAllowance(spender, subtractedValue);
    }

    //------------------------
    //  Helpers
    //------------------------
    function _stablecoin() private view returns (IERC20) {
        return IERC20(IIssuer(state.issuer).getState().stablecoin);
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

}

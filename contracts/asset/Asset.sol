// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Snapshot.sol";
import "../asset/IAsset.sol";
import "../issuer/IIssuer.sol";
import "../managers/crowdfunding-softcap/ICfManagerSoftcap.sol";
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
    event Liquidated(address liquidator, uint256 fundsReceived, uint256 preLiquidationSnapshotId, uint256 timestamp);
    event SetMirroredToken(address caller, address mirroredToken, uint256 timestamp);
    event ConvertFromMirrored(address caller, address mirroredToken, uint256 amount, uint256 timestamp);
    
    //------------------------
    //  CONSTRUCTOR
    //------------------------
    constructor(
        uint256 id,
        address owner,
        address issuer,
        uint256 initialTokenSupply,
        bool whitelistRequiredForTransfer,
        string memory name,
        string memory symbol,
        string memory info
    ) ERC20(name, symbol)
    {
        infoHistory.push(Structs.InfoEntry(
            info,
            block.timestamp
        ));
        bool assetApprovedByIssuer = (IIssuer(issuer).getState().owner == msg.sender);
        address contractAddress = address(this);
        state = Structs.AssetState(
            id,
            contractAddress,
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
            false
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
            "Asset: This functionality is not allowed. Wallet is not approved by the Issuer."
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
        if (newOwner == (IIssuer(state.issuer).getState().owner)) {
            state.assetApprovedByIssuer = true;
        }
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
            "Asset: can't claim mirrored token; Mirrored token was never initialized."
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
        require(_campaignWhitelisted(msg.sender), "Asset: Campaign not approved.");
        state.totalAmountRaised += tokenValue;
        state.totalTokensSold += tokenAmount;
        sellHistory.push(Structs.TokenSaleInfo(
            msg.sender, tokenAmount, tokenValue, block.timestamp
        ));
        emit FinalizeSale(
            msg.sender,
            tokenAmount,
            tokenValue,
            block.timestamp
        );
    }

    function liquidate() external override notLiquidated ownerOnly {
        IERC20 stablecoin = IERC20(IIssuer(state.issuer).getState().stablecoin);
        uint256 liquidationFunds = state.totalAmountRaised;
        stablecoin.safeTransferFrom(msg.sender, address(this), liquidationFunds);
        state.liquidated = true;
        uint256 snapshotId = _snapshot();
        // TODO: - liquidate the mirrored asset too
        emit Liquidated(msg.sender, liquidationFunds, snapshotId, block.timestamp);
    }

    function snapshot() external override notLiquidated returns (uint256) {
        return _snapshot();
    }

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

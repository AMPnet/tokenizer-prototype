// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Snapshot.sol";
import "../asset/IAsset.sol";
import "../issuer/IIssuer.sol";
import "../shared/Structs.sol";

contract Asset is IAsset, ERC20Snapshot {

    //------------------------
    //  STATE
    //------------------------
    Structs.InfoEntry[] private infoHistory;
    Structs.AssetState private state;
    mapping (address => uint256) private approvedCampaignsMap;
    Structs.WalletRecord[] public approvedCampaigns;

    //------------------------
    //  EVENTS
    //------------------------
    event ChangeOwnership(address caller, address newOwner, uint256 timestamp);
    event SetInfo(string info, address setter, uint256 timestamp);
    event SetWhitelistRequiredForTransfer(address caller, bool whitelistRequiredForTransfer, uint256 timestamp);
    event SetApprovedByIssuer(address caller, bool approvedByIssuer, uint256 timestamp);
    event CampaignWhitelist(address approver, address wallet, bool whitelisted, uint256 timestamp);
    event SetIssuerStatus(address approver, bool status, uint256 timestamp);

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
        state = Structs.AssetState(
            id,
            owner,
            address(0),
            initialTokenSupply,
            whitelistRequiredForTransfer,
            assetApprovedByIssuer,
            issuer,
            info,
            name,
            symbol
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
            "This functionality is not allowed. Wallet is not approved by the Issuer."
        );
        _;
    }

    modifier onlyOwner() {
        require(
            msg.sender == state.owner,
            "Only asset creator can make this action."
        );
        _;
    }

    modifier issuerOwnerOnly() {
        require(
            msg.sender == IIssuer(state.issuer).getState().owner,
            "Only issuer owner can make this action." 
        );
        _;
    }

    //------------------------
    //  IAsset IMPL
    //------------------------
    function approveCampaign(address campaign) external override onlyOwner {
        _setCampaignState(campaign, true);
        emit CampaignWhitelist(msg.sender, campaign, true, block.timestamp);
    }

    function suspendCampaign(address campaign) external override onlyOwner {
        _setCampaignState(campaign, false);
        emit CampaignWhitelist(msg.sender, campaign, false, block.timestamp);
    }

    function changeOwnership(address newOwner)
        external
        override
        onlyOwner
    {
        state.owner = newOwner;
        emit ChangeOwnership(msg.sender, newOwner, block.timestamp);
    }

    function setInfo(string memory info) external override onlyOwner {
        infoHistory.push(Structs.InfoEntry(
            info,
            block.timestamp
        ));
        state.info = info;
        emit SetInfo(info, msg.sender, block.timestamp);
    }

    function setWhitelistRequiredForTransfer(bool whitelistRequiredForTransfer) external onlyOwner {
        state.whitelistRequiredForTransfer = whitelistRequiredForTransfer;
        emit SetWhitelistRequiredForTransfer(msg.sender, whitelistRequiredForTransfer, block.timestamp);
    }

    function totalShares() external view override returns (uint256) {
        return totalSupply();
    }

    function getState() external view override returns (Structs.AssetState memory) {
        return state;
    }

    function getInfoHistory() external view override returns (Structs.InfoEntry[] memory) {
        return infoHistory;
    }

    function getDecimals() external view override returns (uint256) {
        return uint256(decimals());
    }

    function getCampaignRecords() external view override returns (Structs.WalletRecord[] memory) {
        return approvedCampaigns;
    }

    function setIssuerStatus(bool status) external override issuerOwnerOnly {
        state.assetApprovedByIssuer = status;
        emit SetIssuerStatus(msg.sender, status, block.timestamp);
    }

    //------------------------
    //  ERC20 OVERRIDES
    //------------------------
    function transfer(address recipient, uint256 amount)
        public
        override
        walletApproved(_msgSender())
        walletApproved(recipient)
        returns (bool)
    {
        return super.transfer(recipient, amount);
    }

    function approve(address spender, uint256 amount)
        public
        override
        walletApproved(_msgSender())
        walletApproved(spender)
        returns (bool)
    {
        return super.approve(spender, amount);
    }

    function transferFrom(address sender, address recipient, uint256 amount)
        public
        override
        walletApproved(sender)
        walletApproved(recipient)
        returns (bool)
    {
        return super.transferFrom(sender, recipient, amount);
    }

    function increaseAllowance(address spender, uint256 addedValue)
        public
        override
        walletApproved(_msgSender())
        walletApproved(spender)
        returns (bool)
    {
        return super.increaseAllowance(spender, addedValue);
    }

    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        override
        walletApproved(_msgSender())
        walletApproved(spender)
        returns (bool)
    {
        return super.decreaseAllowance(spender, subtractedValue);
    }

    //------------------------
    //  ERC20Snapshot
    //------------------------
    function snapshot() external override returns (uint256) {
        return _snapshot();
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
        if (_campaignExists(wallet)) { 
            return approvedCampaigns[approvedCampaignsMap[wallet]].whitelisted;
        }
        else {
            return false;
        }
    }

    function _campaignExists(address wallet) private view returns (bool) {
        uint256 index = approvedCampaignsMap[wallet];
        if (approvedCampaigns.length == 0) { return false; }
        if (index >= approvedCampaigns.length) { return false; }
        if (approvedCampaigns[index].wallet != wallet) { return false; }
        return true;
    }

}

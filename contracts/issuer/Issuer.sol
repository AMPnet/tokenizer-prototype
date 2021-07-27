// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../issuer/IIssuer.sol";
import "../shared/Structs.sol";

contract Issuer is IIssuer {
    //------------------------
    //  STATE
    //------------------------
    Structs.IssuerState private state;
    Structs.InfoEntry[] private infoHistory;
    mapping (address => uint256) public approvedWalletsMap;
    Structs.WalletRecord[] public approvedWallets;
    mapping (address => uint256) private approvedCampaignsMap;
    Structs.WalletRecord[] public approvedCampaigns;

    //------------------------
    //  EVENTS
    //------------------------
    event WalletWhitelist(address approver, address wallet, bool whitelisted, uint256 timestamp);
    event CampaignWhitelist(address approver, address wallet, bool whitelisted, uint256 timestamp);
    event ChangeWalletApprover(address oldWalletApprover, address newWalletApprover, uint256 timestamp);
    event SetInfo(string info, address setter, uint256 timestamp);

    //------------------------
    //  CONSTRUCTOR
    //------------------------
    constructor(
        uint256 id,
        address owner,
        address stablecoin,
        address walletApprover,
        string memory info
    ) {
        infoHistory.push(Structs.InfoEntry(
            info,
            block.timestamp
        ));
        state = Structs.IssuerState(
            id,
            owner,
            stablecoin,
            walletApprover,
            info
        );
    }

    //------------------------
    //  MODIFIERS
    //------------------------
    modifier onlyOwner {
        require(msg.sender == state.owner);
        _;
    }

    modifier onlyWalletApprover {
        require(msg.sender == state.walletApprover);
        _;
    }

    //------------------------
    //  STATE CHANGE FUNCTIONS
    //------------------------
    function approveWallet(address wallet) external onlyWalletApprover {
        _setWalletState(wallet, true, approvedWalletsMap, approvedWallets);
        emit WalletWhitelist(msg.sender, wallet, true, block.timestamp);
    }

    function suspendWallet(address wallet) external onlyWalletApprover {
        _setWalletState(wallet, false, approvedWalletsMap, approvedWallets);
        emit WalletWhitelist(msg.sender, wallet, false, block.timestamp);
    }

    function changeWalletApprover(address newWalletApprover) external onlyOwner {
        state.walletApprover = newWalletApprover;
        emit ChangeWalletApprover(state.walletApprover, newWalletApprover, block.timestamp);
    }

    function approveCampaign(address campaign) external onlyOwner {
        _setWalletState(campaign, true, approvedCampaignsMap, approvedCampaigns);
        emit CampaignWhitelist(msg.sender, campaign, true, block.timestamp);
    }

    function suspendCampaign(address campaign) external onlyOwner {
        _setWalletState(campaign, false, approvedCampaignsMap, approvedCampaigns);
        emit CampaignWhitelist(msg.sender, campaign, false, block.timestamp);
    }

    //------------------------
    //  IIssuer IMPL
    //------------------------
    function setInfo(string memory info) external override onlyOwner {
        infoHistory.push(Structs.InfoEntry(
            info,
            block.timestamp
        ));
        state.info = info;
        emit SetInfo(info, msg.sender, block.timestamp);
    }

    function getState() external override view returns (Structs.IssuerState memory) { return state; }
    
    function isWalletApproved(address wallet) external view override returns (bool) {
        bool walletExists = _addressExists(wallet, approvedWalletsMap, approvedWallets);
        bool campaignExists = _addressExists(wallet, approvedCampaignsMap, approvedCampaigns);
        if (!walletExists && !campaignExists) { return false; }
        if (walletExists) { return approvedWallets[approvedWalletsMap[wallet]].whitelisted; }
        if (campaignExists) { return approvedCampaigns[approvedCampaignsMap[wallet]].whitelisted; }
        return false;
    }

    function getInfoHistory() external view override returns (Structs.InfoEntry[] memory) {
        return infoHistory;
    }

    function getWalletRecords() external view override returns (Structs.WalletRecord[] memory) {
        return approvedWallets;
    }

    function getCampaignRecords() external view override returns (Structs.WalletRecord[] memory) {
        return approvedCampaigns;
    }

    //------------------------
    //  Helpers
    //------------------------
    function _setWalletState(
        address wallet,
        bool whitelisted,
        mapping (address => uint256) storage map,
        Structs.WalletRecord[] storage array
    ) private {
        if (_addressExists(wallet, map, array)) {
            array[map[wallet]].whitelisted = whitelisted;
        } else {
            array.push(Structs.WalletRecord(wallet, whitelisted));
            map[wallet] = array.length - 1;
        }
    }

    function _addressWhitelisted(
        address wallet,
        mapping (address => uint256) storage map,
        Structs.WalletRecord[] storage array
    ) private view returns (bool) {
        if (_addressExists(wallet, map, array)) { return array[map[wallet]].whitelisted; }
        else { return false; }
    }

    function _addressExists(
        address wallet,
        mapping (address => uint256) storage map,
        Structs.WalletRecord[] storage array
    ) private view returns (bool) {
        uint256 index = map[wallet];
        if (array.length == 0) { return false; }
        if (index >= array.length) { return false; }
        if (array[index].wallet != wallet) { return false; }
        return true;
    }

}

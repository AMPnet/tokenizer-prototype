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

    //------------------------
    //  EVENTS
    //------------------------
    event WalletWhitelist(address approver, address wallet, bool whitelisted, uint256 timestamp);
    event ChangeOwnership(address caller, address newOwner, uint256 timestamp);
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
        _setWalletState(owner, true);
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
    function changeWalletApprover(address newWalletApprover) external onlyOwner {
        state.walletApprover = newWalletApprover;
        emit ChangeWalletApprover(state.walletApprover, newWalletApprover, block.timestamp);
    }

    function changeOwnership(address newOwner) external onlyOwner {
        address oldOwner = state.owner;
        state.owner = newOwner;
        _setWalletState(oldOwner, false);
        _setWalletState(newOwner, true);
        emit ChangeOwnership(msg.sender, newOwner, block.timestamp);
    }

    //------------------------
    //  IIssuer IMPL
    //------------------------
    function approveWallet(address wallet) external override onlyWalletApprover {
        _setWalletState(wallet, true);
        emit WalletWhitelist(msg.sender, wallet, true, block.timestamp);
    }

    function suspendWallet(address wallet) external override onlyWalletApprover {
        _setWalletState(wallet, false);
        emit WalletWhitelist(msg.sender, wallet, false, block.timestamp);
    }

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
        bool walletExists = _addressExists(wallet);
        if (!walletExists) {
            return false;
        }
        else {
            return approvedWallets[approvedWalletsMap[wallet]].whitelisted;
        }
    }

    function getInfoHistory() external view override returns (Structs.InfoEntry[] memory) {
        return infoHistory;
    }

    function getWalletRecords() external view override returns (Structs.WalletRecord[] memory) {
        return approvedWallets;
    }

    //------------------------
    //  Helpers
    //------------------------
    function _setWalletState(address wallet, bool whitelisted) private {
        if (_addressExists(wallet)) {
            approvedWallets[approvedWalletsMap[wallet]].whitelisted = whitelisted;
        } else {
            approvedWallets.push(Structs.WalletRecord(wallet, whitelisted));
            approvedWalletsMap[wallet] = approvedWallets.length - 1;
        }
    }

    function _addressWhitelisted(address wallet) private view returns (bool) {
        if (_addressExists(wallet)) { 
            return approvedWallets[approvedWalletsMap[wallet]].whitelisted;
        }
        else {
            return false;
        }
    }

    function _addressExists(address wallet) private view returns (bool) {
        uint256 index = approvedWalletsMap[wallet];
        if (approvedWallets.length == 0) { return false; }
        if (index >= approvedWallets.length) { return false; }
        if (approvedWallets[index].wallet != wallet) { return false; }
        return true;
    }

}

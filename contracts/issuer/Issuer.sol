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
    Structs.WalletRecord[] private approvedWallets;
    mapping (address => uint256) public approvedWalletsMap;

    //------------------------
    //  EVENTS
    //------------------------
    event WalletWhitelist(address indexed approver, address indexed wallet);
    event WalletBlacklist(address indexed approver, address indexed wallet);
    event ChangeOwnership(address caller, address newOwner, uint256 timestamp);
    event ChangeWalletApprover(address caller, address oldWalletApprover, address newWalletApprover, uint256 timestamp);
    event SetInfo(string info, address setter, uint256 timestamp);

    //------------------------
    //  CONSTRUCTOR
    //------------------------
    constructor(
        string memory issuerFlavor,
        string memory issuerVersion,
        address owner,
        address stablecoin,
        address walletApprover,
        string memory info
    ) {
        require(owner != address(0), "Issuer: invalid owner address");
        require(stablecoin != address(0), "Issuer: invalid stablecoin address");
        require(walletApprover != address(0), "Issuer: invalid wallet approver address");
        
        infoHistory.push(Structs.InfoEntry(
            info,
            block.timestamp
        ));
        state = Structs.IssuerState(
            issuerFlavor,
            issuerVersion,
            address(this),
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
    modifier ownerOnly {
        require(
            msg.sender == state.owner,
            "Issuer: Only owner can make this action."
        );
        _;
    }

    modifier walletApproverOnly {
        require(
            msg.sender == state.walletApprover,
            "Issuer: Only wallet approver can make this action."
        );
        _;
    }
    
    //------------------------
    //  IIssuer IMPL
    //------------------------
    function setInfo(string memory info) external override ownerOnly {
        infoHistory.push(Structs.InfoEntry(
            info,
            block.timestamp
        ));
        state.info = info;
        emit SetInfo(info, msg.sender, block.timestamp);
    }

    function approveWallet(address wallet) external override walletApproverOnly {
        _setWalletState(wallet, true);
        emit WalletWhitelist(msg.sender, wallet);
    }

    function suspendWallet(address wallet) external override walletApproverOnly {
        _setWalletState(wallet, false);
        emit WalletBlacklist(msg.sender, wallet);
    }

    function changeOwnership(address newOwner) external override ownerOnly {
        state.owner = newOwner;
        emit ChangeOwnership(msg.sender, newOwner, block.timestamp);
    }

    function changeWalletApprover(address newWalletApprover) external override {
        require(
            msg.sender == state.owner ||
            msg.sender == state.walletApprover,
            "Issuer: not allowed to call this function."
        );
        state.walletApprover = newWalletApprover;
        emit ChangeWalletApprover(msg.sender, state.walletApprover, newWalletApprover, block.timestamp);
    }

    function flavor() external view override returns (string memory) { return state.flavor; }

    function version() external view override returns (string memory) { return state.version; }

    function commonState() external view override returns (Structs.IssuerCommonState memory) {
        return Structs.IssuerCommonState(
            state.flavor,
            state.version,
            state.contractAddress,
            state.owner,
            state.stablecoin,
            state.walletApprover,
            state.info
        );
    }

    function getState() external override view returns (Structs.IssuerState memory) { return state; }
    
    function isWalletApproved(address wallet) external view override returns (bool) {
        return (_addressExists(wallet) && approvedWallets[approvedWalletsMap[wallet]].whitelisted);
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
        return _addressExists(wallet) && approvedWallets[approvedWalletsMap[wallet]].whitelisted;
    }

    function _addressExists(address wallet) private view returns (bool) {
        uint256 index = approvedWalletsMap[wallet];
        if (index >= approvedWallets.length) { return false; }
        return approvedWallets[index].wallet == wallet;
    }

}

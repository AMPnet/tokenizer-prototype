// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../shared/IIssuerCommon.sol";
import "../shared/IVersioned.sol";

contract WalletApproverService is IVersioned {

    string constant public FLAVOR = "WalletApproverServiceV1";
    string constant public VERSION = "1.0.24";

    function flavor() external pure override returns (string memory) { return FLAVOR; }
    function version() external pure override returns (string memory) { return VERSION; } 

    //------------------------
    //  STATE
    //------------------------
    address public masterOwner;
    mapping (address => bool) public allowedApprovers;

    //------------------------
    //  EVENTS
    //------------------------
    event UpdateApproverStatus(address indexed caller, address indexed approver, bool approved, uint256 timestamp);
    event TransferMasterOwnerRights(address indexed caller, address indexed newOwner, uint256 timestamp);
    event ApproveWallet(address indexed caller, address wallet, uint256 timestamp);
    event SuspendWallet(address indexed caller, address wallet, uint256 timestamp);

    //------------------------
    //  CONSTRUCTOR
    //------------------------
    constructor(address _masterOwner, address[] memory approvers) {
        masterOwner = _masterOwner;
        for (uint i=0; i<approvers.length; i++) {
            allowedApprovers[approvers[i]] = true;
        }
        allowedApprovers[masterOwner] = true;
    }

    //------------------------
    //  MODIFIERS
    //------------------------
    modifier isMasterOwner() {
        require(msg.sender == masterOwner, "WalletApproverService: not master owner;");
        _;
    }

    modifier isAllowedToApproveForIssuer(IIssuerCommon issuer) {
        require(
            msg.sender == masterOwner || allowedApprovers[msg.sender],
            "WalletApproverService: approver not in allowed approvers;"
        );
        require(
            issuer.commonState().walletApprover == address(this),
            "WalletApproverService: not allowed to approve for issuer;"
        );
        _;
    }

    //------------------------
    //  STATE CHANGE FUNCTIONS
    //------------------------
    function updateApproverStatus(address approver, bool approved) external isMasterOwner {
        allowedApprovers[approver] = approved;
        emit UpdateApproverStatus(msg.sender, approver, approved, block.timestamp);
    }
    
    function transferMasterOwnerRights(address newMasterOwner) external isMasterOwner {
        allowedApprovers[msg.sender] = false;
        allowedApprovers[newMasterOwner] = true;
        masterOwner = newMasterOwner;
        emit TransferMasterOwnerRights(msg.sender, newMasterOwner, block.timestamp);
    }

    function approveWallets(
        IIssuerCommon issuer,
        address payable [] memory wallets
    ) external isAllowedToApproveForIssuer(issuer) {
        for (uint i=0; i<wallets.length; i++) {
            approveWallet(issuer, wallets[i]);
        }
    }

    function approveWallet(
        IIssuerCommon issuer,
        address payable wallet
    ) public isAllowedToApproveForIssuer(issuer) {
        issuer.approveWallet(wallet);
        emit ApproveWallet(msg.sender, wallet, block.timestamp);
    }

    function suspendWallets(
        IIssuerCommon issuer,
        address[] memory wallets
    ) external isAllowedToApproveForIssuer(issuer) {
        for (uint i=0; i<wallets.length; i++) {
            suspendWallet(issuer, wallets[i]);
        }
    }

    function suspendWallet(
        IIssuerCommon issuer,
        address wallet
    ) public isAllowedToApproveForIssuer(issuer) {
        issuer.suspendWallet(wallet);
        emit SuspendWallet(msg.sender, wallet, block.timestamp);
    }

    function changeWalletApprover(IIssuerCommon issuer, address newWalletApprover) external isMasterOwner {
        issuer.changeWalletApprover(newWalletApprover);
    }

}

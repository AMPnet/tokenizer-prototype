// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../issuer/IIssuer.sol";

contract WalletApproverService {

    //------------------------
    //  STATE
    //------------------------
    address public masterOwner;
    mapping (address => bool) public allowedApprovers;
    uint256 public rewardPerApprove;

    //------------------------
    //  EVENTS
    //------------------------
    event UpdateApproverStatus(address indexed caller, address indexed approver, bool approved, uint256 timestamp);
    event TransferMasterOwnerRights(address indexed caller, address indexed newOwner, uint256 timestamp);
    event ApproveWallet(address indexed caller, address wallet, uint256 timestamp);
    event SuspendWallet(address indexed caller, address wallet, uint256 timestamp);
    event WalletFunded(address indexed caller, address wallet, uint256 reward, uint256 timestamp);
    event UpdateRewardAmount(address indexed caller, uint256 oldAmount, uint256 newAmount, uint256 timestamp);
    event Received(address indexed sender, uint256 amount, uint256 timestamp);
    event Released(address indexed receiver, uint256 amount, uint256 timestamp);

    //------------------------
    //  CONSTRUCTOR
    //------------------------
    constructor(address _masterOwner, address[] memory approvers, uint256 _rewardPerApprove) {
        masterOwner = _masterOwner;
        for (uint i=0; i<approvers.length; i++) {
            allowedApprovers[approvers[i]] = true;
        }
        allowedApprovers[masterOwner] = true;
        rewardPerApprove = _rewardPerApprove;
    }

    //------------------------
    //  MODIFIERS
    //------------------------
    modifier isMasterOwner() {
        require(msg.sender == masterOwner, "WalletApproverService: not master owner;");
        _;
    }

    modifier isAllowedToApproveForIssuer(IIssuer issuer) {
        require(
            allowedApprovers[msg.sender],
            "WalletApproverService: approver not in allowed approvers;"
        );
        require(
            issuer.getState().walletApprover == address(this),
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

    function updateRewardAmount(uint256 newRewardAmount) external isMasterOwner {
        uint256 oldAmount = rewardPerApprove;
        rewardPerApprove = newRewardAmount;
        emit UpdateRewardAmount(msg.sender, oldAmount, newRewardAmount, block.timestamp);
    }

    function approveWallets(
        IIssuer issuer,
        address payable [] memory wallets
    ) external isAllowedToApproveForIssuer(issuer) {
        for (uint i=0; i<wallets.length; i++) {
            approveWallet(issuer, wallets[i]);
        }
    }

    function approveWallet(
        IIssuer issuer,
        address payable wallet
    ) public isAllowedToApproveForIssuer(issuer) {
        if (rewardPerApprove > 0 && address(this).balance >= rewardPerApprove && wallet.balance == 0) {
            wallet.transfer(rewardPerApprove);
            emit WalletFunded(msg.sender, wallet, rewardPerApprove, block.timestamp);
        }
        issuer.approveWallet(wallet);
        emit ApproveWallet(msg.sender, wallet, block.timestamp);
    }

    function suspendWallets(
        IIssuer issuer,
        address[] memory wallets
    ) external isAllowedToApproveForIssuer(issuer) {
        for (uint i=0; i<wallets.length; i++) {
            suspendWallet(issuer, wallets[i]);
        }
    }

    function suspendWallet(
        IIssuer issuer,
        address wallet
    ) public isAllowedToApproveForIssuer(issuer) {
        issuer.suspendWallet(wallet);
        emit SuspendWallet(msg.sender, wallet, block.timestamp);
    }

    //------------------------
    //  NATIVE TOKEN OPS
    //------------------------
    receive() external payable {
        emit Received(msg.sender, msg.value, block.timestamp);
    }

    function release() external isMasterOwner {
        uint256 amount = address(this).balance;
        payable(msg.sender).transfer(amount);
        emit Released(msg.sender, amount, block.timestamp);
    }

}

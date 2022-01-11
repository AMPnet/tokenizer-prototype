// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../shared/IIssuerCommon.sol";
import "../shared/IVersioned.sol";

contract WalletApproverService is IVersioned {

    string constant public FLAVOR = "WalletApproverServiceV1";
    string constant public VERSION = "1.0.26";

    function flavor() external pure override returns (string memory) { return FLAVOR; }
    function version() external pure override returns (string memory) { return VERSION; } 

    //------------------------
    //  STATE
    //------------------------
    address public masterOwner;
    mapping (address => bool) public allowedApprovers;
    uint256 public rewardPerApprove;

    //------------------------
    //  EVENTS
    //------------------------
    event UpdateApproverStatus(address indexed caller, address indexed approver, bool approved);
    event TransferMasterOwnerRights(address indexed caller, address indexed newOwner);
    event ApproveWalletSuccess(address indexed caller, address indexed wallet);
    event ApproveWalletFail(address indexed caller, address indexed wallet);
    event SuspendWalletSuccess(address indexed caller, address indexed wallet);
    event SuspendWalletFail(address indexed caller, address indexed wallet);
    event WalletFunded(address indexed caller, address indexed wallet, uint256 reward);
    event UpdateRewardAmount(address indexed caller, uint256 oldAmount, uint256 newAmount);
    event Received(address indexed sender, uint256 amount);
    event Released(address indexed receiver, uint256 amount);

    //------------------------
    //  CONSTRUCTOR
    //------------------------
    constructor(address _masterOwner, address[] memory _approvers, uint256 _rewardPerApprove) {
        masterOwner = _masterOwner;
        rewardPerApprove = _rewardPerApprove;
        for (uint i=0; i< _approvers.length; i++) {
            allowedApprovers[_approvers[i]] = true;
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
        emit UpdateApproverStatus(msg.sender, approver, approved);
    }
    
    function transferMasterOwnerRights(address newMasterOwner) external isMasterOwner {
        allowedApprovers[msg.sender] = false;
        allowedApprovers[newMasterOwner] = true;
        masterOwner = newMasterOwner;
        emit TransferMasterOwnerRights(msg.sender, newMasterOwner);
    }

    function updateRewardAmount(uint256 newRewardAmount) external isMasterOwner {
        uint256 oldAmount = rewardPerApprove;
        rewardPerApprove = newRewardAmount;
        emit UpdateRewardAmount(msg.sender, oldAmount, newRewardAmount);
    }

    function approveWallets(
        IIssuerCommon issuer,
        address payable [] memory wallets
    ) external isAllowedToApproveForIssuer(issuer) {
        for (uint i=0; i<wallets.length; i++) {
            _approveWallet(issuer, wallets[i]);
        }
    }

    function approveWallet(
        IIssuerCommon issuer,
        address payable wallet
    ) public isAllowedToApproveForIssuer(issuer) {
        _approveWallet(issuer, wallet);
    }

    function suspendWallets(
        IIssuerCommon issuer,
        address[] memory wallets
    ) external isAllowedToApproveForIssuer(issuer) {
        for (uint i=0; i<wallets.length; i++) {
            _suspendWallet(issuer, wallets[i]);
        }
    }

    function suspendWallet(
        IIssuerCommon issuer,
        address wallet
    ) public isAllowedToApproveForIssuer(issuer) {
        _suspendWallet(issuer, wallet);
    }

    function changeWalletApprover(IIssuerCommon issuer, address newWalletApprover) external isMasterOwner {
        issuer.changeWalletApprover(newWalletApprover);
    }

    //------------------------
    //  NATIVE TOKEN OPS
    //------------------------
    receive() external payable {
        emit Received(msg.sender, msg.value);
    }

    function release() external isMasterOwner {
        uint256 amount = address(this).balance;
        payable(msg.sender).transfer(amount);
        emit Released(msg.sender, amount);
    }

    //------------------------
    //  HELPERS
    //------------------------
    function _approveWallet(IIssuerCommon issuer, address payable wallet) private {
        (bool success,) = address(issuer).call(
            abi.encodeWithSignature("approveWallet(address)", wallet)
        );
        if (success) {
            emit ApproveWalletSuccess(msg.sender, wallet);
        } else {
            emit ApproveWalletFail(msg.sender, wallet);
        }

        if (rewardPerApprove > 0 && wallet.balance == 0 && address(this).balance >= rewardPerApprove) {
            wallet.transfer(rewardPerApprove);
            emit WalletFunded(msg.sender, wallet, rewardPerApprove);
        }
    }

    function _suspendWallet(IIssuerCommon issuer, address wallet) private {
        (bool success,) = address(issuer).call(
            abi.encodeWithSignature("suspendWallet(address)", wallet)
        );
        if (success) {
            emit SuspendWalletSuccess(msg.sender, wallet);
        } else {
            emit SuspendWalletFail(msg.sender, wallet);
        }
    }

}

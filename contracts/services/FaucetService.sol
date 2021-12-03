// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../shared/IVersioned.sol";

contract FaucetService is IVersioned {

    string constant public FLAVOR = "FaucetServiceV1";
    string constant public VERSION = "1.0.24";

    //------------------------
    //  STATE
    //------------------------
    address public masterOwner;
    mapping (address => bool) public allowedCallers;
    uint256 public rewardPerApprove;

    //------------------------
    //  EVENTS
    //------------------------
    event UpdateCallerStatus(address indexed caller, address indexed approver, bool approved, uint256 timestamp);
    event WalletFunded(address indexed caller, address wallet, uint256 reward, uint256 timestamp);
    event UpdateRewardAmount(address indexed caller, uint256 oldAmount, uint256 newAmount, uint256 timestamp);
    event Received(address indexed sender, uint256 amount, uint256 timestamp);
    event Released(address indexed receiver, uint256 amount, uint256 timestamp);

    //------------------------
    //  CONSTRUCTOR
    //------------------------
    constructor(address _masterOwner, address[] memory _callers, uint256 _rewardPerApprove) {
        masterOwner = _masterOwner;
        for (uint i=0; i< _callers.length; i++) {
            allowedCallers[_callers[i]] = true;
        }
        allowedCallers[masterOwner] = true;
        rewardPerApprove = _rewardPerApprove;
    }

    //------------------------
    //  MODIFIERS
    //------------------------
    modifier isMasterOwner() {
        require(msg.sender == masterOwner, "FaucetService: not master owner;");
        _;
    }

    modifier isAllowed() {
        require(
            msg.sender == masterOwner || allowedCallers[msg.sender],
            "FaucetService: not master owner;"
        );
        _;
    }

    function flavor() external pure override returns (string memory) { return FLAVOR; }
    function version() external pure override returns (string memory) { return VERSION; }

    //------------------------
    //  STATE CHANGE FUNCTIONS
    //------------------------
    function faucet(address payable[] calldata wallets) public isAllowed() {
        if (rewardPerApprove == 0 || address(this).balance < (rewardPerApprove * wallets.length)) { return; }
        for (uint256 i = 0; i < wallets.length; i++) {
            if (wallets[i].balance == 0) {
                wallets[i].transfer(rewardPerApprove);
                emit WalletFunded(msg.sender, wallets[i], rewardPerApprove, block.timestamp);
            }
        }
    }

    function updateRewardAmount(uint256 newRewardAmount) external isMasterOwner {
        uint256 oldAmount = rewardPerApprove;
        rewardPerApprove = newRewardAmount;
        emit UpdateRewardAmount(msg.sender, oldAmount, newRewardAmount, block.timestamp);
    }

    function updateCallerStatus(address caller, bool approved) external isMasterOwner {
        allowedCallers[caller] = approved;
        emit UpdateCallerStatus(msg.sender, caller, approved, block.timestamp);
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../shared/IVersioned.sol";

interface IFaucetService is IVersioned {
    event UpdateCallerStatus(address indexed caller, address indexed approver, bool approved, uint256 timestamp);
    event WalletFunded(address indexed caller, address indexed wallet, uint256 reward);
    event UpdateRewardAmount(address indexed caller, uint256 oldAmount, uint256 newAmount, uint256 timestamp);
    event UpdateBalanceThresholdForReward(address indexed caller, uint256 oldThreshold, uint256 newThreshold, uint256 timestamp);
    event OwnershipChanged(address indexed oldOwner, address indexed newOwner, uint256 timestamp);
    event Received(address indexed sender, uint256 amount, uint256 timestamp);
    event Released(address indexed receiver, uint256 amount, uint256 timestamp);

    function faucet(address payable[] calldata _wallets) external;
    function updateRewardAmount(uint256 _newRewardAmount) external;
    function updateBalanceThresholdForReward(uint256 _newBalanceThresholdForReward) external;
    function updateCallerStatus(address _caller, bool _approved) external;
    function transferOwnership(address _newOwner) external;
    receive() external payable;
    function release() external;
}

contract FaucetService is IFaucetService {

    string constant public FLAVOR = "FaucetServiceV1";
    string constant public VERSION = "1.0.30";

    function flavor() external pure override returns (string memory) { return FLAVOR; }
    function version() external pure override returns (string memory) { return VERSION; }

    //------------------------
    //  STATE
    //------------------------
    address public masterOwner;
    mapping (address => bool) public allowedCallers;
    uint256 public rewardPerApprove;
    uint256 public balanceThresholdForReward;

    //------------------------
    //  CONSTRUCTOR
    //------------------------
    constructor(address _masterOwner, address[] memory _callers, uint256 _rewardPerApprove, uint256 _balanceThresholdForReward) {
        require(_masterOwner != address(0), "FaucetService: invalid master owner");
        require(_rewardPerApprove > 0, "FaucetService: reward per approve must not be zero");
        
        for (uint i = 0; i < _callers.length; i++) {
            require(_callers[i] != address(0), "FaucetService: invalid caller address");
            allowedCallers[_callers[i]] = true;
        }

        masterOwner = _masterOwner;
        rewardPerApprove = _rewardPerApprove;
        balanceThresholdForReward = _balanceThresholdForReward;
    }

    //------------------------
    //  MODIFIERS
    //------------------------
    modifier isMasterOwner {
        require(msg.sender == masterOwner, "FaucetService: not master owner");
        _;
    }

    modifier isAllowed {
        require(
            msg.sender == masterOwner || allowedCallers[msg.sender],
            "FaucetService: not allowed to call function"
        );
        _;
    }

    //------------------------
    //  STATE CHANGE FUNCTIONS
    //------------------------
    function faucet(address payable[] calldata _wallets) external override isAllowed {
        require(address(this).balance >= (rewardPerApprove * _wallets.length), "FaucetService: insufficient balance");

        for (uint256 i = 0; i < _wallets.length; i++) {
            if (_wallets[i].balance <= balanceThresholdForReward) {
                _wallets[i].transfer(rewardPerApprove);
                emit WalletFunded(msg.sender, _wallets[i], rewardPerApprove);
            }
        }
    }

    function updateRewardAmount(uint256 _newRewardAmount) external override isMasterOwner {
        require(_newRewardAmount > 0, "FaucetService: reward per approve must be not be zero");
        uint256 oldAmount = rewardPerApprove;
        rewardPerApprove = _newRewardAmount;
        emit UpdateRewardAmount(msg.sender, oldAmount, _newRewardAmount, block.timestamp);
    }

    function updateBalanceThresholdForReward(uint256 _newBalanceThresholdForReward) external override isMasterOwner {
        uint256 oldBalanceThresholdForReward = balanceThresholdForReward;
        balanceThresholdForReward = _newBalanceThresholdForReward;
        emit UpdateBalanceThresholdForReward(
            msg.sender,
            oldBalanceThresholdForReward,
            _newBalanceThresholdForReward,
            block.timestamp
        );
    }

    function updateCallerStatus(address _caller, bool _approved) external override isMasterOwner {
        require(_caller != address(0), "FaucetService: invalid caller address");
        allowedCallers[_caller] = _approved;
        emit UpdateCallerStatus(msg.sender, _caller, _approved, block.timestamp);
    }

    function transferOwnership(address _newOwner) external override isMasterOwner {
        require(_newOwner != address(0), "FaucetService: invalid new master owner");
        address oldOwner = masterOwner;
        masterOwner = _newOwner;
        emit OwnershipChanged(oldOwner, _newOwner, block.timestamp);
    }

    //------------------------
    //  NATIVE TOKEN OPS
    //------------------------
    receive() external override payable {
        emit Received(msg.sender, msg.value, block.timestamp);
    }

    function release() external override isMasterOwner {
        uint256 amount = address(this).balance;
        payable(msg.sender).transfer(amount);
        emit Released(msg.sender, amount, block.timestamp);
    }
}

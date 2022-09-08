// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Rewarder is Ownable {

    event AddReward(bytes32 secretHash);
    event ClaimReward(address wallet, bytes32 secretHash);
    event DrainToken(address token, uint256 amount);
    event Drain(uint256 amount);

    struct Reward {
        bytes32 secretHash;
        address token;
        uint256 amount;
        uint256 nativeAmount;
        uint256 expiresAt;
    }

    mapping (bytes32 => Reward) rewards;
    mapping (bytes32 => bool) claimed;

    constructor(address owner) {
        _transferOwnership(owner);
    }

    function addRewards(Reward[] memory _rewards) public onlyOwner {
        for (uint256 i = 0; i < _rewards.length; i++) {
            rewards[_rewards[i].secretHash] = _rewards[i];
            emit AddReward(_rewards[i].secretHash);
        }
    }

    function claimReward(string memory key) public {
        bytes memory data = abi.encodePacked(address(this), key);
        bytes32 calculatedHash = keccak256(data);
        Reward memory reward = rewards[calculatedHash];
        require(
            reward.secretHash == calculatedHash,
            "Key does not exist!"
        );
        require(
            !claimed[calculatedHash],
            "Reward with this key already claimed!"
        );
        require(
            block.timestamp <= reward.expiresAt,
            "Reward expired!"
        );
        claimed[calculatedHash] = true;
        if (reward.amount > 0) {
            IERC20(reward.token).transfer(msg.sender, reward.amount);
        }
        if (reward.nativeAmount > 0) {
            payable(msg.sender).transfer(reward.nativeAmount);
        }
        emit ClaimReward(msg.sender, calculatedHash);
    }

    function drain(address tokenAddress) public onlyOwner {
        IERC20 token = IERC20(tokenAddress);
        uint256 amount = token.balanceOf(address(this));
        if (amount > 0) {
            token.transfer(msg.sender, amount);
            emit DrainToken(tokenAddress, amount);
        }
    }

    function drain() public onlyOwner {
        uint256 amount = address(this).balance;
        if (amount > 0) {
            payable(msg.sender).transfer(amount);
            emit Drain(amount);
        }
    }

    receive() external payable { }

}

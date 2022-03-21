// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract TimeLockManager {
    using SafeERC20 for IERC20;

    event Lock(address indexed sender, uint256 amount);
    event Unlock(address indexed receiver, uint256 amount);

    IERC20 public token;
    uint256 public deadline;

    mapping (address => uint256) public locks;

    constructor(address _token, uint256 _deadline) {
        require(_token != address(0), "TimeLockManager:: token is 0x0");
        require(_deadline > block.timestamp, "TimeLockManager:: deadline must be in the future");
        token = IERC20(_token);
        deadline = _deadline;
    }

    function lock(uint256 amount) public {
        require(amount > 0, "TimeLockManager: amount is  0");
        require(block.timestamp < deadline, "TimeLockManager:: manager expired");
        uint256 approvedAmount = token.allowance(msg.sender, address(this));
        require(approvedAmount > 0, "TimeLockManager:: allowance is 0");
        locks[msg.sender] += approvedAmount;
        token.safeTransferFrom(msg.sender, address(this), approvedAmount);
        emit Lock(msg.sender, amount);
    }

    function unlock(address spender) public {
        uint256 lockedAmount = locks[spender];
        require(lockedAmount > 0, "TimeLockManager:: locked amount is 0");
        require(block.timestamp >= deadline, "TimeLockManager:: deadline not reached");
        locks[spender] = 0;
        token.safeTransfer(spender, lockedAmount);
        emit Unlock(spender, lockedAmount);
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract TimeLockManager {
    using SafeERC20 for IERC20;

    struct TokenLock {
        address token;
        uint256 amount;
        uint256 createdAt;
        uint256 duration;
        string info;
        bool released;
    }

    event Lock(address indexed sender, address indexed token, uint256 amount, uint256 duration);
    event Unlock(address indexed receiver, address indexed token, uint256 id, uint256 amount);

    mapping (address => TokenLock[]) public locks;

    function lock(address tokenAddress, uint256 amount, uint256 duration, string memory info) public {
        require(amount > 0, "TimeLockManager: amount is 0");
        require(duration > 0, "TimeLockManager: duration is 0");

        IERC20 token = IERC20(tokenAddress);
        require(
            token.allowance(msg.sender, address(this)) >= amount,
            "TimeLockManager:: missing allowance"
        );
        require(
            token.balanceOf(msg.sender) >= amount,
            "TimeLockManager:: balance not enough"
        );

        locks[msg.sender].push(
            TokenLock(
                tokenAddress,
                amount,
                block.timestamp,
                duration,
                info,
                false
            )
        );
        token.safeTransferFrom(msg.sender, address(this), amount);

        emit Lock(msg.sender, tokenAddress, amount, duration);
    }

    function unlock(address spender, uint256 index) public {
        require(
            index < locks[spender].length,
            "TimeLockManager:: index out of bounds"
        );
        TokenLock storage tokenLock = locks[spender][index];
        require(
            !tokenLock.released,
            "TimeLockManager:: tokens already released"
        );
        require(
            block.timestamp > (tokenLock.createdAt + tokenLock.duration),
            "TimeLockManager:: deadline not reached"
        );

        tokenLock.released = true;
        IERC20(tokenLock.token).safeTransfer(spender, tokenLock.amount);
        emit Unlock(spender, tokenLock.token, index, tokenLock.amount);
    }

    function tokenLocksList(address wallet) external view returns (TokenLock[] memory) {
        return locks[wallet];
    }

}

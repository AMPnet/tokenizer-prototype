// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ITimeLockManager {

    struct TokenLock {
        address token;
        uint256 amount;
        uint256 createdAt;
        uint256 duration;
        string info;
        bool released;
        address unlockPrivilegeWallet;
    }

    event Lock(address indexed sender, address indexed token, uint256 amount, uint256 duration);
    event Unlock(address indexed receiver, address indexed token, uint256 id, uint256 amount);

    function lock(
        address tokenAddress,
        uint256 amount,
        uint256 duration,
        string memory info,
        address unlockPrivilegeWallet
    ) external;

    function unlock(address spender, uint256 index) external;

    function tokenLocksList(address wallet) external view returns (TokenLock[] memory);

}

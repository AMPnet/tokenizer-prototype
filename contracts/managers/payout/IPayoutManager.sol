// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IPayoutManager {
    function totalShares() external view returns (uint256);
    function totalReleased(uint256 snapshotId) external view returns (uint256);
    function shares(address account, uint256 snapshotId) external view returns (uint256);
    function released(address account, uint256 snapshotId) external view returns (uint256);
    function release(address account, uint256 snapshotId) external;
}


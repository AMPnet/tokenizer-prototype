// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20Snapshot {
    function snapshot() external returns (uint256);
    function totalSupplyAt(uint256 snapshotId) external view returns (uint256); 
    function balanceOfAt(address account, uint256 snapshotId) external view returns (uint256);
}

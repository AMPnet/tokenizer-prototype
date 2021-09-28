// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IVersioned.sol";
import "./Structs.sol";

interface ISnapshotDistributorCommon is IVersioned {

    // WRITE
    function setInfo(string memory info) external;
    function release(address account, uint256 snapshotId) external;

    // READ
    function commonState() external view returns (Structs.SnapshotDistributorCommonState memory);
    function shares(address account, uint256 snapshotId) external view returns (uint256);
    function released(address account, uint256 snapshotId) external view returns (uint256);
    function totalReleased(uint256 snapshotId) external view returns (uint256);

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../../shared/Structs.sol";

interface IPayoutManager {
    function totalShares() external view returns (uint256);
    function totalReleased(uint256 snapshotId) external view returns (uint256);
    function shares(address account, uint256 snapshotId) external view returns (uint256);
    function released(address account, uint256 snapshotId) external view returns (uint256);
    function release(address account, uint256 snapshotId) external;
    function getInfoHistory() external view returns (Structs.InfoEntry[] memory);
    function setInfo(string memory info) external;
    function getState() external view returns (Structs.PayoutManagerState memory);
    function getPayouts() external view returns (Structs.Payout[] memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../../shared/ISnapshotDistributorCommon.sol";
import "../../shared/Structs.sol";

interface ISnapshotDistributor is ISnapshotDistributorCommon {
    function getInfoHistory() external view returns (Structs.InfoEntry[] memory);
    function getPayouts() external view returns (Structs.Payout[] memory);
}

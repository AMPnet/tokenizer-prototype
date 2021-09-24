// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../../shared/ISnapshotDistributorFactoryCommon.sol";

interface ISnapshotDistributorFactory is ISnapshotDistributorFactoryCommon {
    function create(
        address owner,
        string memory mappedName,
        address assetAddress,
        string memory info,
        address nameRegistry
    ) external returns (address);
}

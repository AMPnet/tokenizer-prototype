// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../shared/Structs.sol";

interface IAssetTransferableDeployer {
    function create(
        string memory flavor,
        string memory version,
        Structs.AssetTransferableFactoryParams memory params
    ) external returns (address);
}

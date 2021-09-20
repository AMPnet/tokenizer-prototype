// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../shared/Structs.sol";

interface IAssetDeployer {
    function create(
        string memory flavor,
        string memory version,
        Structs.AssetFactoryParams memory params
    ) external returns (address);
}

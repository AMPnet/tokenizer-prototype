// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../shared/Structs.sol";
import "../shared/IAssetFactoryCommon.sol";

interface IAssetFactory is IAssetFactoryCommon {
    
    function create(Structs.AssetFactoryParams memory params) external returns (address);
    
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../shared/Structs.sol";
import "../shared/IAssetFactoryCommon.sol";

interface IAssetSimpleFactory is IAssetFactoryCommon {
    
    function create(Structs.AssetSimpleFactoryParams memory params) external returns (address);
    
}

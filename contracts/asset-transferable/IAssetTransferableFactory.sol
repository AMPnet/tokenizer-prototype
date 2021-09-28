// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../shared/Structs.sol";
import "../shared/IAssetFactoryCommon.sol";

interface IAssetTransferableFactory is IAssetFactoryCommon {

    function create(Structs.AssetTransferableFactoryParams memory params) external returns (address);
    
}

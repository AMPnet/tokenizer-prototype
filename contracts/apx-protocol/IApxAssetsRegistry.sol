// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../shared/Structs.sol";

interface IApxAssetsRegistry {

    // WRITE
    function transferMasterOwnerRole(address newMasterOwner) external;
    function transferAssetManagerRole(address newAssetManager) external;
    function transferPriceManagerRole(address newPriceManager) external;
    function registerAsset(address original, address mirrored, bool state) external;
    function updateState(address asset, bool state) external;
    function updatePrice(address asset, uint256 price, uint256 pricePrecision, uint256 expiry) external;
    function migrate(address newAssetsRegistry, address originalAsset) external;

    // READ
    function getMirrored(address asset) external view returns (Structs.AssetRecord memory);
    function getMirroredFromOriginal(address original) external view returns (Structs.AssetRecord memory);
    function getMirroredList() external view returns (address[] memory);

}

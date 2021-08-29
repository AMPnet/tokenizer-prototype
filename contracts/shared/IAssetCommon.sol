// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IAssetCommon {
    function finalizeSale() external;
    function getIssuerAddress() external view returns (address);
    function getAssetFactory() external view returns (address);
    function priceDecimalsPrecision() external view returns (uint256);
}

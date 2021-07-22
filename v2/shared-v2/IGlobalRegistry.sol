// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IGlobalRegistry {
    function issuerFactory() external view returns (address);
    function assetFactory() external view returns (address);
    function cfManagerFactory() external view returns (address);
    function payoutManagerFactory() external view returns (address);
}

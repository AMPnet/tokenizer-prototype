// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IIssuerFactory {
    function create(
        address _owner,
        address _stablecoin, 
        address _assetFactory, 
        address _cfManagerFactory
    ) external returns (address);
}

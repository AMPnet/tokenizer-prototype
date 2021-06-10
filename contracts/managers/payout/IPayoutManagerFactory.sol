// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IPayoutManagerFactory {
    function create(address owner, address assetAddress) external returns (address);
    function getInstances() external view returns (address[] memory);
}
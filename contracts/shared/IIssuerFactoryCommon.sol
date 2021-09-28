// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IIssuerFactoryCommon {
    function getInstances() external view returns (address[] memory);
}

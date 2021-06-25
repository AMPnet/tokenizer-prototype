// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IIssuerFactory {
    function create(
        address _owner,
        address _stablecoin,
        address _registry,
        address _walletApprover,
        string memory _info
    ) external returns (address);

    function getInstances() external view returns (address[] memory);
}

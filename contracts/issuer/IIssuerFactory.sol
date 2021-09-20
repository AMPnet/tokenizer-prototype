// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IIssuerFactory {
    
    function create(
        address _owner,
        string memory _mappedName,
        address _stablecoin,
        address _walletApprover,
        string memory _info,
        address _nameRegistry
    ) external returns (address);

    function getInstances() external view returns (address[] memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IIssuerFactory {
    
    function create(
        address _owner,
        string memory _ansName,
        address _stablecoin,
        address _walletApprover,
        string memory _info
    ) external returns (address);

    function getInstances() external view returns (address[] memory);
    function namespace(string memory ansName) external view returns (address);
}

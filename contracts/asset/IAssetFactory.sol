// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IAssetFactory {
    
    function create(
        address creator,
        address issuer,
        address apxRegistry,
        string memory ansName,
        uint256 initialTokenSupply,
        bool isTransferable,
        bool whitelistRequiredForTransfer,
        string memory name,
        string memory symbol,
        string memory info
    ) external returns (address);
    
    function getInstances() external view returns (address[] memory);
    
    function getInstancesForIssuer(address issuer) external view returns (address[] memory);

    function namespace(address issuer, string memory ansName) external view returns (address);
    
}

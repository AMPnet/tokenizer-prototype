// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IAssetFactory {
    
    function create(
        address creator,
        address issuer,
        uint256 initialTokenSupply,
        bool whitelistRequiredForTransfer,
        string memory name,
        string memory symbol,
        string memory info
    ) external returns (address);
    
    function getInstances() external view returns (address[] memory);
    
    function getInstancesForIssuer(address issuer) external view returns (address[] memory);

}

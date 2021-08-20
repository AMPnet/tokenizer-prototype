// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IAssetTransferableFactory {

    function create(
        address creator,
        address issuer,
        string memory ansName,
        uint256 initialTokenSupply,
        bool whitelistRequiredForRevenueClaim,
        bool whitelistRequiredForLiquidationClaim,
        string memory name,
        string memory symbol,
        string memory info,
        address childChainManager
    ) external returns (address);
    
    function getInstances() external view returns (address[] memory);
    
    function getInstancesForIssuer(address issuer) external view returns (address[] memory);

    function namespace(address issuer, string memory ansName) external view returns (address);
    
}

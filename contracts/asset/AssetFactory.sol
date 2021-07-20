// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../asset/IAssetFactory.sol";
import "../asset/Asset.sol";

contract AssetFactory is IAssetFactory {
    
    event AssetCreated(address indexed creator, address asset, uint256 id, uint256 timestamp);

    address[] public instances;
    mapping (address => address[]) instancesPerIssuer;

    function create(
        address creator,
        address issuer,
        uint256 initialTokenSupply,
        bool whitelistRequiredForTransfer,
        string memory name,
        string memory symbol,
        string memory info
    ) public override returns (address)
    {
        uint256 id = instances.length;
        address asset = address(new Asset(
            id,
            creator,
            issuer,
            initialTokenSupply,
            whitelistRequiredForTransfer,
            name,
            symbol,
            info
        ));
        instances.push(asset);
        instancesPerIssuer[issuer].push(asset);
        emit AssetCreated(creator, asset, id, block.timestamp);
        return asset;
    }

    function getInstances() external override view returns (address[] memory) { return instances; }
    
    function getInstancesForIssuer(address issuer) external override view returns (address[] memory) { 
        return instancesPerIssuer[issuer];
    }
}

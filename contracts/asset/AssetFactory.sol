// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../asset/IAssetFactory.sol";
import "../asset/Asset.sol";
import "../shared/Structs.sol";

contract AssetFactory is IAssetFactory {
    
    event AssetCreated(address indexed creator, address asset, uint256 id, uint256 timestamp);

    address[] public instances;
    mapping (address => address[]) instancesPerIssuer;
    mapping (address => mapping (string => address)) public override namespace;

    function create(
        address creator,
        address issuer,
        address apxRegistry,
        string memory ansName,
        uint256 initialTokenSupply,
        bool whitelistRequiredForRevenueClaim,
        bool whitelistRequiredForLiquidationClaim,
        string memory name,
        string memory symbol,
        string memory info
    ) public override returns (address)
    {
        require(namespace[issuer][ansName] == address(0), "AssetFactory: asset with this name already exists");
        uint256 id = instances.length;
        uint256 ansId = instancesPerIssuer[issuer].length;
        address asset = 
            address(
                new Asset(
                    Structs.AssetConstructorParams(
                        id,
                        creator,
                        issuer,
                        apxRegistry,
                        ansName,
                        ansId,
                        initialTokenSupply,
                        whitelistRequiredForRevenueClaim,
                        whitelistRequiredForLiquidationClaim,
                        name,
                        symbol,
                        info
                    )
        ));
        instances.push(asset);
        instancesPerIssuer[issuer].push(asset);
        namespace[issuer][ansName] = asset;
        emit AssetCreated(creator, asset, id, block.timestamp);
        return asset;
    }

    function getInstances() external override view returns (address[] memory) { return instances; }
    
    function getInstancesForIssuer(address issuer) external override view returns (address[] memory) { 
        return instancesPerIssuer[issuer];
    }
}

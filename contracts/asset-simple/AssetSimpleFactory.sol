// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IAssetSimpleFactory.sol";
import "./AssetSimple.sol";
import "../shared/Structs.sol";
import "../registry/INameRegistry.sol";

contract AssetSimpleFactory is IAssetSimpleFactory {
    
    string constant public FLAVOR = "AssetSimpleV1";
    string constant public VERSION = "1.0.15";

    address[] public instances;
    mapping (address => address[]) instancesPerIssuer;

    event AssetSimpleCreated(address indexed creator, address asset, uint256 timestamp);

    function create(Structs.AssetSimpleFactoryParams memory params) public override returns (address) {
        INameRegistry nameRegistry = INameRegistry(params.nameRegistry);
        require(
            nameRegistry.getAsset(params.mappedName) == address(0),
            "AssetSimpleFactory: asset with this name already exists"
        );
        address asset = address(new AssetSimple(
                Structs.AssetSimpleConstructorParams(
                    FLAVOR,
                    VERSION,
                    params.creator,
                    params.issuer,
                    params.initialTokenSupply,
                    params.name,
                    params.symbol,
                    params.info
                )
            )
        );
        instances.push(asset);
        instancesPerIssuer[params.issuer].push(asset);
        emit AssetSimpleCreated(params.creator, asset, block.timestamp);
        return asset;
    }

    function getInstances() external override view returns (address[] memory) { return instances; }
    
    function getInstancesForIssuer(address issuer) external override view returns (address[] memory) { 
        return instancesPerIssuer[issuer];
    }

}

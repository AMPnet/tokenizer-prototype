// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IAssetTransferableFactory.sol";
import "../deployers/IAssetTransferableDeployer.sol";
import "../shared/Structs.sol";
import "../registry/INameRegistry.sol";

contract AssetTransferableFactory is IAssetTransferableFactory {

    string constant public FLAVOR = "AssetTransferableV1";
    string constant public VERSION = "1.0.14";
    
    address public deployer;
    address[] public instances;
    mapping (address => address[]) instancesPerIssuer;

    event AssetTransferableCreated(address indexed creator, address asset, uint256 timestamp);

    constructor(address _deployer) { deployer = _deployer; }

    function create(Structs.AssetTransferableFactoryParams memory params) public override returns (address) {
        INameRegistry nameRegistry = INameRegistry(params.nameRegistry);
        require(
            nameRegistry.getAsset(params.mappedName) == address(0),
            "AssetTransferableFactory: asset with this name already exists"
        );
        address asset = IAssetTransferableDeployer(deployer).create(FLAVOR, VERSION, params);
        instances.push(asset);
        instancesPerIssuer[params.issuer].push(asset);
        nameRegistry.mapAsset(params.mappedName, asset);
        emit AssetTransferableCreated(params.creator, asset, block.timestamp);
        return asset;
    }

    function getInstances() external override view returns (address[] memory) { return instances; }
    
    function getInstancesForIssuer(address issuer) external override view returns (address[] memory) { 
        return instancesPerIssuer[issuer];
    }
}

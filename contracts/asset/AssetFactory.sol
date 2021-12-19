// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IAssetFactory.sol";
import "../deployers/IAssetDeployer.sol";
import "../shared/Structs.sol";
import "../shared/IAssetCommon.sol";
import "../registry/INameRegistry.sol";

contract AssetFactory is IAssetFactory {

    string constant public FLAVOR = "AssetV1";
    string constant public VERSION = "1.0.24";

    address public deployer;
    address[] public instances;
    mapping (address => address[]) instancesPerIssuer;

    event AssetCreated(address indexed creator, address asset, uint256 timestamp);

    constructor(address _deployer, address _oldFactory) { 
        deployer = _deployer; 
        if (_oldFactory != address(0)) { _addInstances(IAssetFactory(_oldFactory).getInstances()); }
    }

    function create(Structs.AssetFactoryParams memory params) public override returns (address) {
        INameRegistry nameRegistry = INameRegistry(params.nameRegistry);
        require(
            nameRegistry.getAsset(params.mappedName) == address(0),
            "AssetFactory: asset with this name already exists"
        );
        address asset = IAssetDeployer(deployer).create(FLAVOR, VERSION, params);
        _addInstance(asset);
        emit AssetCreated(params.creator, asset, block.timestamp);
        return asset;
    }

    function getInstances() external override view returns (address[] memory) { return instances; }
    
    function getInstancesForIssuer(address issuer) external override view returns (address[] memory) { 
        return instancesPerIssuer[issuer];
    }

    /////////// HELPERS ///////////

    function _addInstances(address[] memory _instances) private {
        if (_instances.length == 0) { return; }
        for (uint256 i = 0; i < _instances.length; i++) { _addInstance(_instances[i]); }
    }

    function _addInstance(address _instance) private {
        instances.push(_instance);
        instancesPerIssuer[IAssetCommon(_instance).commonState().issuer].push(_instance);
    }

}

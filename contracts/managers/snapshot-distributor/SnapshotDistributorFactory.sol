// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ISnapshotDistributorFactory.sol";
import "./SnapshotDistributor.sol";
import "../../issuer/IIssuer.sol";
import "../../shared/IAssetCommon.sol";
import "../../shared/ISnapshotDistributorCommon.sol";
import "../../registry/INameRegistry.sol";

contract SnapshotDistributorFactory is ISnapshotDistributorFactory {

    string constant public FLAVOR = "SnapshotDistributorV1";
    string constant public VERSION = "1.0.27";

    event SnapshotDistributorCreated(
        address indexed creator,
        address distributor,
        address asset,
        uint256 timestamp
    );

    address[] public instances;
    bool public initialized;
    mapping (address => address[]) instancesPerIssuer;
    mapping (address => address[]) instancesPerAsset;

    constructor(address _oldFactory) { 
        if (_oldFactory != address(0)) { _addInstances(ISnapshotDistributorFactory(_oldFactory).getInstances()); }
    }

    function create(
        address owner,
        string memory mappedName,
        address assetAddress,
        string memory info,
        address nameRegistry
    ) public override returns (address) {
        INameRegistry registry = INameRegistry(nameRegistry);
        require(
            registry.getSnapshotDistributor(mappedName) == address(0),
            "SnapshotDistributorFactory: distributor with this name already exists"
        );
        address snapshotDistributor = address(new SnapshotDistributor(FLAVOR, VERSION, owner, assetAddress, info));
        address issuer = IAssetCommon(assetAddress).commonState().issuer;
        instances.push(snapshotDistributor);
        instancesPerIssuer[issuer].push(snapshotDistributor);
        instancesPerAsset[assetAddress].push(snapshotDistributor);
        registry.mapSnapshotDistributor(mappedName, snapshotDistributor);
        emit SnapshotDistributorCreated(owner, snapshotDistributor, assetAddress, block.timestamp);
        return snapshotDistributor;
    }

    function getInstances() external override view returns (address[] memory) { return instances; }
    
    function getInstancesForIssuer(address issuer) external override view returns (address[] memory) {
        return instancesPerIssuer[issuer];
    }

    function getInstancesForAsset(address asset) external override view returns (address[] memory) {
        return instancesPerAsset[asset];
    }

    function addInstancesForNewRegistry(
        address oldFactory,
        address oldNameRegistry,
        address newNameRegistry
    ) external override {
        require(!initialized, "SnapshotDistributorFactory: Already initialized");
        address[] memory _instances = ISnapshotDistributorFactory(oldFactory).getInstances();
        for (uint256 i = 0; i < _instances.length; i++) {
            address instance = _instances[i];
            _addInstance(instance);
            string memory oldName = INameRegistry(oldNameRegistry).getSnapshotDistributorName(instance);
            if (bytes(oldName).length > 0) { INameRegistry(newNameRegistry).mapSnapshotDistributor(oldName, instance); }
        }
        initialized = true;
    }

    /////////// HELPERS ///////////

    function _addInstances(address[] memory _instances) private {
        for (uint256 i = 0; i < _instances.length; i++) { _addInstance(_instances[i]); }
    }

    function _addInstance(address _instance) private {
        address asset = ISnapshotDistributorCommon(_instance).commonState().asset;
        address issuer = IAssetCommon(asset).commonState().issuer;
        instances.push(_instance);
        instancesPerIssuer[issuer].push(_instance);
        instancesPerAsset[asset].push(_instance);
    }

}

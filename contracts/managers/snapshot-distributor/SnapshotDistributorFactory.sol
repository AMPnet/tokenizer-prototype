// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ISnapshotDistributorFactory.sol";
import "./SnapshotDistributor.sol";
import "../../issuer/IIssuer.sol";
import "../../shared/IAssetCommon.sol";
import "../../registry/INameRegistry.sol";

contract SnapshotDistributorFactory is ISnapshotDistributorFactory {

    string constant public FLAVOR = "SnapshotDistributorV1";
    string constant public VERSION = "1.0.15";

    event SnapshotDistributorCreated(
        address indexed creator,
        address distributor,
        address asset,
        uint256 timestamp
    );

    address[] public instances;
    mapping (address => address[]) instancesPerIssuer;
    mapping (address => address[]) instancesPerAsset;

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
    
}

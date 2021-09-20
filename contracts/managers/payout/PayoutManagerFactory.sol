// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IPayoutManagerFactory.sol";
import "./PayoutManager.sol";
import "../../issuer/IIssuer.sol";
import "../../shared/IAssetCommon.sol";
import "../../registry/INameRegistry.sol";

contract PayoutManagerFactory is IPayoutManagerFactory {

    string constant public FLAVOR = "PayoutManagerV1";
    string constant public VERSION = "1.0.13";

    event PayoutManagerCreated(
        address indexed creator,
        address payoutManager,
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
        // TODO: check for registry if manager exists
        address payoutManager = address(new PayoutManager(FLAVOR, VERSION, owner, assetAddress, info));
        address issuer = IAssetCommon(assetAddress).commonState().issuer;
        instances.push(payoutManager);
        instancesPerIssuer[issuer].push(payoutManager);
        instancesPerAsset[assetAddress].push(payoutManager);
        // TODO: map manager
        emit PayoutManagerCreated(owner, payoutManager, assetAddress, block.timestamp);
        return payoutManager;
    }

    function getInstances() external override view returns (address[] memory) { return instances; }
    
    function getInstancesForIssuer(address issuer) external override view returns (address[] memory) {
        return instancesPerIssuer[issuer];
    }

    function getInstancesForAsset(address asset) external override view returns (address[] memory) {
        return instancesPerAsset[asset];
    }
    
}

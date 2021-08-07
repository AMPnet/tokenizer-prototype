// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IPayoutManagerFactory.sol";
import "./PayoutManager.sol";
import "../../asset/IAsset.sol";
import "../../issuer/IIssuer.sol";

contract PayoutManagerFactory is IPayoutManagerFactory {

    event PayoutManagerCreated(
        address indexed creator,
        address payoutManager,
        uint256 id,
        address asset,
        uint256 timestamp
    );

    address[] public instances;
    mapping (address => address[]) instancesPerIssuer;
    mapping (address => address[]) instancesPerAsset;
    mapping (address => mapping (string => address)) public override namespace;

    function create(
        address owner,
        string memory ansName,
        address assetAddress,
        string memory info
    ) public override returns (address) {
        address issuer = IAsset(assetAddress).getState().issuer;
        require(
            namespace[issuer][ansName] == address(0),
            "PayoutManagerFactory: issuer with this name already exists"
        );
        uint256 id = instances.length;
        uint256 ansId = instancesPerIssuer[issuer].length;
        address payoutManager = address(new PayoutManager(id, owner, ansName, ansId, assetAddress, info));
        instances.push(payoutManager);
        instancesPerIssuer[issuer].push(payoutManager);
        instancesPerAsset[assetAddress].push(payoutManager);
        namespace[issuer][ansName] = payoutManager;
        emit PayoutManagerCreated(owner, payoutManager, id, assetAddress, block.timestamp);
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

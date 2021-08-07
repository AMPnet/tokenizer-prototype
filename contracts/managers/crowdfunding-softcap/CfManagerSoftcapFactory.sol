// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./CfManagerSoftcap.sol";
import "./ICfManagerSoftcapFactory.sol";
import "../../asset/IAsset.sol";

contract CfManagerSoftcapFactory is ICfManagerSoftcapFactory {

    address[] public instances;
    mapping (address => address[]) instancesPerIssuer;
    mapping (address => address[]) instancesPerAsset;
    mapping (address => mapping(string => address)) public override namespace;

    event CfManagerSoftcapCreated(
        address indexed creator,
        address cfManager,
        uint256 id,
        address asset,
        uint256 timestamp
    );

    function create(
        address owner,
        string memory ansName,
        address assetAddress,
        uint256 initialPricePerToken,
        uint256 softCap,
        uint256 minInvestment,
        uint256 maxInvestment,
        bool whitelistRequired,
        string memory info
    ) external override returns (address) {
        address issuer = IAsset(assetAddress).getState().issuer;
        require(
            namespace[issuer][ansName] == address(0),
            "CfManagerSoftcapFactory: issuer with this name already exists"
        );
        uint256 id = instances.length;
        uint256 ansId = instancesPerIssuer[issuer].length;
        address cfManagerSoftcap = address(new CfManagerSoftcap(
            id,
            owner,
            ansName,
            ansId,
            assetAddress,
            initialPricePerToken,
            softCap,
            minInvestment,
            maxInvestment,
            whitelistRequired,
            info
        ));
        instances.push(cfManagerSoftcap);
        instancesPerIssuer[issuer].push(cfManagerSoftcap);
        instancesPerAsset[assetAddress].push(cfManagerSoftcap);
        namespace[issuer][ansName] = cfManagerSoftcap;
        emit CfManagerSoftcapCreated(owner, cfManagerSoftcap, id, address(assetAddress), block.timestamp);
        return cfManagerSoftcap;
    }

    function getInstances() external override view returns (address[] memory) { return instances; }

    function getInstancesForIssuer(address issuer) external override view returns (address[] memory) {
        return instancesPerIssuer[issuer];
    }

    function getInstancesForAsset(address asset) external override view returns (address[] memory) {
        return instancesPerAsset[asset];
    }

}

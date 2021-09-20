// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./CfManagerSoftcap.sol";
import "./ICfManagerSoftcapFactory.sol";
import "../../shared/IAssetCommon.sol";
import "../../registry/INameRegistry.sol";

contract CfManagerSoftcapFactory is ICfManagerSoftcapFactory {
    
    string constant public FLAVOR = "CfManagerSoftcapV1";
    string constant public VERSION = "1.0.13";
    
    address[] public instances;
    mapping (address => address[]) instancesPerIssuer;
    mapping (address => address[]) instancesPerAsset;

    event CfManagerSoftcapCreated(
        address indexed creator,
        address cfManager,
        address asset,
        uint256 timestamp
    );

    function create(
        address owner,
        string memory mappedName,
        address assetAddress,
        uint256 initialPricePerToken,
        uint256 softCap,
        uint256 minInvestment,
        uint256 maxInvestment,
        bool whitelistRequired,
        string memory info,
        address nameRegistry
    ) external override returns (address) {
        INameRegistry registry = INameRegistry(nameRegistry);
        require(
            registry.getCampaign(mappedName) == address(0),
            "CfManagerSoftcapFactory: campaign with this name already exists"
        );
        address cfManagerSoftcap = address(new CfManagerSoftcap(
            FLAVOR,
            VERSION,
            owner,
            assetAddress,
            initialPricePerToken,
            softCap,
            minInvestment,
            maxInvestment,
            whitelistRequired,
            info
        ));
        instances.push(cfManagerSoftcap);
        address issuer = IAssetCommon(assetAddress).commonState().issuer;
        instancesPerIssuer[issuer].push(cfManagerSoftcap);
        instancesPerAsset[assetAddress].push(cfManagerSoftcap);
        registry.mapCampaign(mappedName, cfManagerSoftcap);
        emit CfManagerSoftcapCreated(owner, cfManagerSoftcap, address(assetAddress), block.timestamp);
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

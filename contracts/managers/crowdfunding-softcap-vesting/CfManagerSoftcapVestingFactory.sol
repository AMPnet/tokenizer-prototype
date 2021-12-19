// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./CfManagerSoftcapVesting.sol";
import "./ICfManagerSoftcapVestingFactory.sol";
import "../../shared/IAssetCommon.sol";
import "../../shared/ICampaignCommon.sol";
import "../../registry/INameRegistry.sol";

contract CfManagerSoftcapVestingFactory is ICfManagerSoftcapVestingFactory {
    
    string constant public FLAVOR = "CfManagerSoftcapVestingV1";
    string constant public VERSION = "1.0.24";
    
    address[] public instances;
    mapping (address => address[]) instancesPerIssuer;
    mapping (address => address[]) instancesPerAsset;

    event CfManagerSoftcapVestingCreated(
        address indexed creator,
        address cfManager,
        address asset,
        uint256 timestamp
    );

    constructor(address _oldFactory) { 
        if (_oldFactory != address(0)) { _addInstances(ICfManagerSoftcapVestingFactory(_oldFactory).getInstances()); }
    }

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
        address nameRegistry,
        address feeManager
    ) external override returns (address) {
        INameRegistry registry = INameRegistry(nameRegistry);
        require(
            registry.getCampaign(mappedName) == address(0),
            "CfManagerSoftcapVestingFactory: campaign with this name already exists"
        );
        address cfManagerSoftcap = address(new CfManagerSoftcapVesting(
            FLAVOR,
            VERSION,
            owner,
            assetAddress,
            initialPricePerToken,
            softCap,
            minInvestment,
            maxInvestment,
            whitelistRequired,
            info,
            feeManager
        ));
        _addInstance(cfManagerSoftcap);
        registry.mapCampaign(mappedName, cfManagerSoftcap);
        emit CfManagerSoftcapVestingCreated(owner, cfManagerSoftcap, address(assetAddress), block.timestamp);
        return cfManagerSoftcap;
    }

    function getInstances() external override view returns (address[] memory) { return instances; }

    function getInstancesForIssuer(address issuer) external override view returns (address[] memory) {
        return instancesPerIssuer[issuer];
    }

    function getInstancesForAsset(address asset) external override view returns (address[] memory) {
        return instancesPerAsset[asset];
    }

    /////////// HELPERS ///////////

    function _addInstances(address[] memory _instances) private {
        if (_instances.length == 0) { return; }
        for (uint256 i = 0; i < _instances.length; i++) { _addInstance(_instances[i]); }
    }

    function _addInstance(address _instance) private {
        address asset = ICampaignCommon(_instance).commonState().asset;
        address issuer = IAssetCommon(asset).commonState().issuer;
        instances.push(_instance);
        instancesPerIssuer[issuer].push(_instance);
        instancesPerAsset[asset].push(_instance);
    }

}

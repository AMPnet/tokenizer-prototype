// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./CfManagerSoftcap.sol";
import "./ICfManagerSoftcapFactory.sol";
import "../../shared/ICampaignCommon.sol";
import "../../registry/INameRegistry.sol";

contract CfManagerSoftcapFactory is ICfManagerSoftcapFactory {
    
    string constant public FLAVOR = "CfManagerSoftcapV1";
    string constant public VERSION = "1.0.27";
    
    address[] public instances;
    bool public initialized;
    mapping (address => address[]) instancesPerIssuer;
    mapping (address => address[]) instancesPerAsset;

    event CfManagerSoftcapCreated(
        address indexed creator,
        address cfManager,
        address asset,
        uint256 timestamp
    );

    constructor(address _oldFactory) { 
        if (_oldFactory != address(0)) { _addInstances(ICfManagerSoftcapFactory(_oldFactory).getInstances()); }
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
            info,
            feeManager
        ));
        _addInstance(cfManagerSoftcap);
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

    function addInstancesForNewRegistry(
        address oldFactory,
        address oldNameRegistry,
        address newNameRegistry
    ) external override {
        require(!initialized, "CfManagerSoftcapFactory: Already initialized");
        address[] memory _instances = ICfManagerSoftcapFactory(oldFactory).getInstances();
        for (uint256 i = 0; i < _instances.length; i++) {
            address instance = _instances[i];
            _addInstance(instance);
            string memory oldName = INameRegistry(oldNameRegistry).getCampaignName(instance);
            if (bytes(oldName).length > 0) { INameRegistry(newNameRegistry).mapCampaign(oldName, instance); }
        }
        initialized = true;
    }

    /////////// HELPERS ///////////

    function _addInstances(address[] memory _instances) private {
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

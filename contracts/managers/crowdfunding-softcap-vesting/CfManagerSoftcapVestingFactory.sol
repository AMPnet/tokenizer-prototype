// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./CfManagerSoftcapVesting.sol";
import "./ICfManagerSoftcapVestingFactory.sol";
import "../../shared/IAssetCommon.sol";
import "../../shared/ICampaignCommon.sol";
import "../../registry/INameRegistry.sol";
import "../../shared/Structs.sol";

contract CfManagerSoftcapVestingFactory is ICfManagerSoftcapVestingFactory {
    
    string constant public FLAVOR = "CfManagerSoftcapVestingV1";
    string constant public VERSION = "1.0.27";
    
    address[] public instances;
    bool public initialized;
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

    function create(Structs.CampaignFactoryParams memory params) external override returns (address) {
        INameRegistry registry = INameRegistry(params.nameRegistry);
        require(
            registry.getCampaign(params.mappedName) == address(0),
            "CfManagerSoftcapVestingFactory: campaign with this name already exists"
        );
        address cfManagerSoftcap = address(
            new CfManagerSoftcapVesting(
                Structs.CampaignConstructor(
                    FLAVOR,
                    VERSION,
                    params.owner,
                    params.assetAddress,
                    params.issuerAddress,
                    params.paymentMethod,
                    params.initialPricePerToken,
                    params.tokenPricePrecision,
                    params.softCap,
                    params.minInvestment,
                    params.maxInvestment,
                    params.whitelistRequired,
                    params.info,
                    params.feeManager
                )
        ));
        _addInstance(cfManagerSoftcap);
        registry.mapCampaign(params.mappedName, cfManagerSoftcap);
        emit CfManagerSoftcapVestingCreated(
            params.owner,
            cfManagerSoftcap,
            address(params.assetAddress),
            block.timestamp
        );
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
        require(!initialized, "CfManagerSoftcapVestingFactory: Already initialized");
        address[] memory _instances = ICfManagerSoftcapVestingFactory(oldFactory).getInstances();
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

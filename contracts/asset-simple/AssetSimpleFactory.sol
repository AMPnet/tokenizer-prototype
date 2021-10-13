// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IAssetSimpleFactory.sol";
import "./AssetSimple.sol";
import "../shared/Structs.sol";
import "../shared/IAssetCommon.sol";
import "../registry/INameRegistry.sol";

contract AssetSimpleFactory is IAssetSimpleFactory {
    
    string constant public FLAVOR = "AssetSimpleV1";
    string constant public VERSION = "1.0.20";

    address[] public instances;
    mapping (address => address[]) instancesPerIssuer;

    event AssetSimpleCreated(address indexed creator, address asset, uint256 timestamp);

    constructor(address _oldFactory) {
        if (_oldFactory != address(0)) { _addInstances(IAssetSimpleFactory(_oldFactory).getInstances()); }
    }

    function create(Structs.AssetSimpleFactoryParams memory params) public override returns (address) {
        INameRegistry nameRegistry = INameRegistry(params.nameRegistry);
        require(
            nameRegistry.getAsset(params.mappedName) == address(0),
            "AssetSimpleFactory: asset with this name already exists"
        );
        address asset = address(new AssetSimple(
                Structs.AssetSimpleConstructorParams(
                    FLAVOR,
                    VERSION,
                    params.creator,
                    params.issuer,
                    params.initialTokenSupply,
                    params.name,
                    params.symbol,
                    params.info
                )
            )
        );
        _addInstance(asset);
        emit AssetSimpleCreated(params.creator, asset, block.timestamp);
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

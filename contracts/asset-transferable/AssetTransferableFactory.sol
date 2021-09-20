// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IAssetTransferableFactory.sol";
import "./AssetTransferable.sol";
import "../shared/Structs.sol";
import "../registry/INameRegistry.sol";

contract AssetTransferableFactory is IAssetTransferableFactory {

    string constant public FLAVOR = "AssetTransferableV1";
    string constant public VERSION = "1.0.13";
    
    event AssetTransferableCreated(address indexed creator, address asset, uint256 timestamp);

    address[] public instances;
    mapping (address => address[]) instancesPerIssuer;

    function create(Structs.AssetTransferableFactoryParams memory params) public override returns (address) {
        INameRegistry nameRegistry = INameRegistry(params.nameRegistry);
        require(
            nameRegistry.getAsset(params.mappedName) == address(0),
            "AssetTransferableFactory: asset with this name already exists"
        );
        address asset = 
            address(
                new AssetTransferable(
                    Structs.AssetTransferableConstructorParams(
                        FLAVOR,
                        VERSION,
                        params.creator,
                        params.issuer,
                        params.apxRegistry,
                        params.initialTokenSupply,
                        params.whitelistRequiredForRevenueClaim,
                        params.whitelistRequiredForLiquidationClaim,
                        params.name,
                        params.symbol,
                        params.info,
                        params.childChainManager
                    )
        ));
        instances.push(asset);
        instancesPerIssuer[params.issuer].push(asset);
        nameRegistry.mapAsset(params.mappedName, asset);
        emit AssetTransferableCreated(params.creator, asset, block.timestamp);
        return asset;
    }

    function getInstances() external override view returns (address[] memory) { return instances; }
    
    function getInstancesForIssuer(address issuer) external override view returns (address[] memory) { 
        return instancesPerIssuer[issuer];
    }
}

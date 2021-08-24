// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IAssetTransferableFactory.sol";
import "./AssetTransferable.sol";
import "../shared/Structs.sol";

contract AssetTransferableFactory is IAssetTransferableFactory {
    
    event AssetTransferableCreated(address indexed creator, address asset, uint256 id, uint256 timestamp);

    address[] public instances;
    mapping (address => address[]) instancesPerIssuer;
    mapping (address => mapping (string => address)) public override namespace;

    function create(Structs.AssetTransferableFactoryParams memory params) public override returns (address) {
        require(
            namespace[params.issuer][params.ansName] == address(0),
            "AssetTransferableFactory: asset with this name already exists"
        );
        uint256 id = instances.length;
        uint256 ansId = instancesPerIssuer[params.issuer].length;
        address asset = 
            address(
                new AssetTransferable(
                    Structs.AssetTransferableConstructorParams(
                        id,
                        params.creator,
                        params.issuer,
                        params.apxRegistry,
                        params.ansName,
                        ansId,
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
        namespace[params.issuer][params.ansName] = asset;
        emit AssetTransferableCreated(params.creator, asset, id, block.timestamp);
        return asset;
    }

    function getInstances() external override view returns (address[] memory) { return instances; }
    
    function getInstancesForIssuer(address issuer) external override view returns (address[] memory) { 
        return instancesPerIssuer[issuer];
    }
}

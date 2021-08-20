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

    function create(
        address creator,
        address issuer,
        string memory ansName,
        uint256 initialTokenSupply,
        bool whitelistRequiredForRevenueClaim,
        bool whitelistRequiredForLiquidationClaim,
        string memory name,
        string memory symbol,
        string memory info,
        address childChainManager
    ) public override returns (address)
    {
        require(
            namespace[issuer][ansName] == address(0),
            "AssetTransferableFactory: asset with this name already exists"
        );
        uint256 id = instances.length;
        uint256 ansId = instancesPerIssuer[issuer].length;
        address asset = address(new AssetTransferable(
            id,
            creator,
            issuer,
            ansName,
            ansId,
            initialTokenSupply,
            whitelistRequiredForRevenueClaim,
            whitelistRequiredForLiquidationClaim,
            name,
            symbol,
            info,
            childChainManager
        ));
        instances.push(asset);
        instancesPerIssuer[issuer].push(asset);
        namespace[issuer][ansName] = asset;
        emit AssetTransferableCreated(creator, asset, id, block.timestamp);
        return asset;
    }

    function getInstances() external override view returns (address[] memory) { return instances; }
    
    function getInstancesForIssuer(address issuer) external override view returns (address[] memory) { 
        return instancesPerIssuer[issuer];
    }
}

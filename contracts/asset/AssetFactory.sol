// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { IAssetFactory } from "../asset/IAssetFactory.sol";
import { Asset } from "../asset/Asset.sol";
import { AssetFundingState } from "../shared/Enums.sol";

contract AssetFactory is IAssetFactory {
    
    event AssetCreated(address indexed creator, address asset, uint256 timestamp);

    address[] public instances;

    function create(
        address creator,
        address issuer,
        AssetFundingState fundingState,
        uint256 initialTokenSupply,
        uint256 initialPricePerToken,
        string memory name,
        string memory symbol,
        string memory info
    ) public override returns (address)
    {
        uint256 id = instances.length;
        address asset = address(new Asset(
            id,
            creator,
            issuer,
            fundingState,
            initialTokenSupply,
            initialPricePerToken,
            name,
            symbol,
            info
        ));
        instances.push(asset);
        emit AssetCreated(creator, asset, block.timestamp);
        return asset;
    }

    function getInstances() external override view returns (address[] memory) { return instances; }
    
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { IAssetFactory } from "../asset/IAssetFactory.sol";
import { Asset } from "../asset/Asset.sol";
import { AssetState } from "../shared/Enums.sol";

contract AssetFactory is IAssetFactory {
    
    event AssetCreated(address _asset);

    address[] public instances;

    function create(
        address _creator,
        address _issuer,
        AssetState _state,
        uint256 _categoryId,
        uint256 _totalShares,
        string memory _name,
        string memory _symbol
    ) public override returns (address)
    {
        address asset = address(new Asset(
            _creator,
            _issuer,
            _state,
            _categoryId,
            _totalShares,
            _name,
            _symbol
        ));
        instances.push(asset);
        emit AssetCreated(asset);
        return asset;
    }

    function getInstances() external override view returns (address[] memory) { return instances; }
    
}

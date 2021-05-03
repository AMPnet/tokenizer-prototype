// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { IAssetFactory } from "./interfaces/IAssetFactory.sol";
import { Asset } from "./Asset.sol";
import { AssetState } from "./Enums.sol";

contract AssetFactory is IAssetFactory {

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
        return address(new Asset(
            _creator,
            _issuer,
            _state,
            _categoryId,
            _totalShares,
            _name,
            _symbol
        ));
    }

}

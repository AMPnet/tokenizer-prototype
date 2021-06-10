// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { AssetState } from "../shared/Enums.sol";

interface IAssetFactory {
    function create(
        address _creator,
        address _issuer,
        AssetState _state,
        uint256 _categoryId,
        uint256 _totalShares,
        string memory _name,
        string memory _symbol
    ) external returns (address);
    
    function getInstances() external view returns (address[] memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { SyntheticState } from "../Enums.sol";

interface ISyntheticFactory {
    function create(
        address _creator,
        address _issuer,
        SyntheticState _state,
        uint256 _categoryId,
        uint256 _totalShares,
        string memory _name,
        string memory _symbol
    ) external returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { ISyntheticFactory } from "./interfaces/ISyntheticFactory.sol";
import { Synthetic } from "./Synthetic.sol";
import { SyntheticState } from "./Enums.sol";

contract SyntheticFactory is ISyntheticFactory {

    function create(
        address _creator,
        address _issuer,
        SyntheticState _state,
        uint256 _categoryId,
        uint256 _totalShares,
        string memory _name,
        string memory _symbol
    ) public override returns (address)
    {
        return address(new Synthetic(
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

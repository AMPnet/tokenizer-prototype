// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { ICfManagerFactory } from "./ICfManagerFactory.sol";
import { CfManager } from "./CfManager.sol";

contract CfManagerFactory is ICfManagerFactory {

    function create(
        uint256 _minInvestment,
        uint256 _maxInvestment,
        uint256 _endsAt
    ) public override returns (address)
    {
        return address(new CfManager(
            _minInvestment,
            _maxInvestment,
            _endsAt
        ));
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { ICfManagerFactory } from "./ICfManagerFactory.sol";
import { CfManager } from "./CfManager.sol";

contract CfManagerFactory is ICfManagerFactory {

    event CfManagerCreated(address _cfManager);

    address[] public instances;

    function create(
        address _owner,
        uint256 _minInvestment,
        uint256 _maxInvestment,
        uint256 _endsAt
    ) public override returns (address)
    {
        address cfManager = address(new CfManager(
            _owner,
            _minInvestment,
            _maxInvestment,
            _endsAt
        ));
        instances.push(cfManager);
        emit CfManagerCreated(cfManager);
        return cfManager;
    }

    function getInstances() external override view returns (address[] memory) { return instances; }

}

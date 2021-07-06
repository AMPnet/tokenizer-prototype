// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { ICfManagerFactory } from "./ICfManagerFactory.sol";
import { CfManager } from "./CfManager.sol";

contract CfManagerFactory is ICfManagerFactory {

    event CfManagerCreated(address indexed creator, address cfManager, uint256 timestamp);

    address[] public instances;

    function create(
        address owner,
        uint256 initialPricePerToken,
        uint256 minInvestment,
        uint256 maxInvestment,
        uint256 endsAt,
        string memory info
    ) public override returns (address)
    {
        uint256 id = instances.length;
        address cfManager = address(new CfManager(
            id,
            owner,
            initialPricePerToken,
            minInvestment,
            maxInvestment,
            endsAt,
            info
        ));
        instances.push(cfManager);
        emit CfManagerCreated(owner, cfManager, block.timestamp);
        return cfManager;
    }

    function getInstances() external override view returns (address[] memory) { return instances; }

}

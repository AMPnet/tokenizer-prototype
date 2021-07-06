// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { IPayoutManagerFactory } from "./IPayoutManagerFactory.sol";
import { PayoutManager } from "./PayoutManager.sol";

contract PayoutManagerFactory is IPayoutManagerFactory {

    event PayoutManagerCreated(address indexed creator, address payoutManager, uint256 timestamp);

    address[] public instances;

    function create(address owner, address assetAddress, string memory info) public override returns (address) {
        uint256 id = instances.length;
        address payoutManager = address(new PayoutManager(id, owner, assetAddress, info));
        instances.push(payoutManager);
        emit PayoutManagerCreated(owner, payoutManager, block.timestamp);
        return payoutManager;
    }

    function getInstances() external override view returns (address[] memory) { return instances; }
    
}

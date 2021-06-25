// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { IPayoutManagerFactory } from "./IPayoutManagerFactory.sol";
import { PayoutManager } from "./PayoutManager.sol";

contract PayoutManagerFactory is IPayoutManagerFactory {

    event PayoutManagerCreated(address _payoutManager);

    address[] public instances;

    function create(address owner, address assetAddress) public override returns (address) {
        uint256 id = instances.length;
        address payoutManager = address(new PayoutManager(id, owner, assetAddress));
        instances.push(payoutManager);
        emit PayoutManagerCreated(payoutManager);
        return payoutManager;
    }

    function getInstances() external override view returns (address[] memory) { return instances; }
    
}

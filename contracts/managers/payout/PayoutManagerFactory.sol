// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { IPayoutManagerFactory } from "./IPayoutManagerFactory.sol";
import { PayoutManager } from "./PayoutManager.sol";

contract PayoutManagerFactory is IPayoutManagerFactory {

    event PayoutManagerCreated(address _payoutManager);

    function create(address owner, address assetAddress) public override returns (address) {
        address payoutManager = address(new PayoutManager(owner, assetAddress));
        emit PayoutManagerCreated(payoutManager);
        return payoutManager;
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { IPayoutManagerFactory } from "./IPayoutManagerFactory.sol";
import { PayoutManager } from "./PayoutManager.sol";

contract PayoutManagerFactory is IPayoutManagerFactory {

    function create(address owner, address assetAddress) public override returns (address) {
        return address(new PayoutManager(owner, assetAddress));
    }

}

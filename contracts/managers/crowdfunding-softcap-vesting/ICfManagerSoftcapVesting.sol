// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../IACfManager.sol";
import "../../shared/Structs.sol";

interface ICfManagerSoftcapVesting is IACfManager {
    function getState() external view returns (Structs.CfManagerSoftcapVestingState memory);
}

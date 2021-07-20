// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { InfoEntry, CfManagerSoftcapState } from "../../shared/Structs.sol";

interface ICfManagerSoftcap {
    function setInfo(string memory info) external;
    function getInfoHistory() external view returns (InfoEntry[] memory);
    function getState() external view returns (CfManagerSoftcapState memory);
}

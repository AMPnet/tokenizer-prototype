// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../../shared/Structs.sol";

interface ICfManagerSoftcap {
    function setInfo(string memory info) external;
    function getInfoHistory() external view returns (Structs.InfoEntry[] memory);
    function getState() external view returns (Structs.CfManagerSoftcapState memory);
    function changeOwnership(address newOwner) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../../shared/ICampaignCommon.sol";
import "../../shared/Structs.sol";

interface ICfManagerSoftcap is ICampaignCommon {
    function getInfoHistory() external view returns (Structs.InfoEntry[] memory);
    function getState() external view returns (Structs.CfManagerSoftcapState memory);
    function changeOwnership(address newOwner) external;
}

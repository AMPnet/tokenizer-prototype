// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../../shared/ICampaignFactoryCommon.sol";
import "../../shared/Structs.sol";

interface ICfManagerSoftcapFactory is ICampaignFactoryCommon {
    function create(Structs.CampaignFactoryParams memory params) external returns (address);
}

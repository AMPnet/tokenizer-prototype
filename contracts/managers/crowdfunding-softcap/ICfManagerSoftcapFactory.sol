// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../../shared/ICampaignFactoryCommon.sol";

interface ICfManagerSoftcapFactory is ICampaignFactoryCommon {
    function create(
        address owner,
        string memory mappedName,
        address assetAddress,
        uint256 initialPricePerToken,
        uint256 softCap,
        uint256 minInvestment,
        uint256 maxInvestment,
        bool whitelistRequired,
        string memory info,
        address nameRegistry,
        address feeManager
    ) external returns (address);
}

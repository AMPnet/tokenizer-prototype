// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../../shared/IVersioned.sol";

interface IFeeManager is IVersioned {
    function setDefaultFee(bool initialized, uint256 numerator, uint256 denominator) external;
    function setCampaignFee(address campaign, bool initialized, uint256 numerator, uint256 denominator) external;
    function calculateFee(address campaign) external view returns (address, uint256);
}

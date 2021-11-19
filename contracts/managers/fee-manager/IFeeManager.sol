// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IFeeManager {
    function setDefaultFee(bool initialized, uint256 numerator, uint256 denominator) external;
    function setCampaignFee(address campaign, bool initialized, uint256 numerator, uint256 denominator) external;
    function calculateFee(address campaign) external view returns (address, uint256);
}

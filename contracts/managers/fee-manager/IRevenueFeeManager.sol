// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../../shared/IVersioned.sol";

interface IRevenueFeeManager is IVersioned  {
    event SetAssetFee(address asset, bool initialized, uint256 nominator, uint256 denominator, uint256 timestamp);

    function setAssetFee(address asset, bool initialized, uint256 numerator, uint256 denominator) external;
    function setIssuerFee(
        address issuer,
        address queryService,
        address[] calldata factories,
        address nameRegistry,
        bool initialized,
        uint256 numerator,
        uint256 denominator
    ) external;
    function calculateFee(address asset, uint256 amount) external view returns (address treasury, uint256 fee);
}

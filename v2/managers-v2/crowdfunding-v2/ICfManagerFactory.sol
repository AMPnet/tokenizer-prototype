// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ICfManagerFactory {
    function create(
        address owner,
        uint256 initialPricePerToken,
        uint256 minInvestment,
        uint256 maxInvestment,
        uint256 endsAt,
        string memory info
    ) external returns (address);

    function getInstances() external view returns (address[] memory);
}

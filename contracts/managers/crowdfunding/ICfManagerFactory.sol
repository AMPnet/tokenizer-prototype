// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ICfManagerFactory {
    function create(
        uint256 _minInvestment,
        uint256 _maxInvestment,
        uint256 _endsAt
    ) external returns (address);
}

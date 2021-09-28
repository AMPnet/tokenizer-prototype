// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IApxAsset {
    function lockTokens(uint256 amount) external;
    function unlockTokens(address wallet, uint256 amount) external;
    function migrateApxRegistry(address newRegistry) external;
}

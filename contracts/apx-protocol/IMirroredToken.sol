// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IMirroredToken {
    function mintMirrored(address wallet, uint256 amount) external;
    function burnMirrored(uint256 amount) external;
    function setChildChainManager(address childChainManager) external;
}

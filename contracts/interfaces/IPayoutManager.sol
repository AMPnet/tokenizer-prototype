// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IPayoutManager {
    function totalShares() external view returns (uint256);
    function totalReleased() external view returns (uint256);
    function shares(address account) external view returns (uint256);
    function released(address account) external view returns (uint256);
    function payee(uint256 index) external view returns (address);
    function release(address account) external;
}


// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { IIssuer } from "./IIssuer.sol";

interface IAsset {
    function issuer() external view returns (IIssuer);
    function creator() external view returns (address);
    function totalShares() external view returns (uint256);
    function addShareholder(address shareholder, uint256 amount) external returns (bool);
}

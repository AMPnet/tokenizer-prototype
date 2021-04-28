// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { IIssuer } from "./IIssuer.sol";

interface ISynthetic {
    function issuer() external returns (IIssuer);
    function creator() external returns (address);
    function totalShares() external returns (uint256);
    function addShareholder(address shareholder, uint256 amount) external returns (bool);
}

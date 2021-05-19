// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { IIssuer } from "../issuer/IIssuer.sol";
import { AssetState } from "../shared/Enums.sol";

interface IAsset {
    function issuer() external view returns (IIssuer);
    function creator() external view returns (address);
    function totalShares() external view returns (uint256);
    function info() external returns (string memory);
    function state() external returns (AssetState);
    function addShareholder(address shareholder, uint256 amount) external;
    function removeShareholder(address shareholder, uint256 amount) external;
    function finalize() external;
    function snapshot() external returns (uint256);
    function setCreator(address newCreator) external;
}

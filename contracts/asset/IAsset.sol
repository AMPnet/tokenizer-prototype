// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../shared/Structs.sol";

interface IAsset {
    function totalShares() external view returns (uint256);
    function getDecimals() external view returns (uint256);
    function getState() external view returns (Structs.AssetState memory);
    function getInfoHistory() external view returns (Structs.InfoEntry[] memory);
    function setInfo(string memory info) external;
    function snapshot() external returns (uint256);
    function setOwner(address newOwner) external;
}

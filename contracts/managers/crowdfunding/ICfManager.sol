// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { InfoEntry } from "../../shared/Structs.sol";

interface ICfManager {
    function setAsset(address _assetAddress) external;
    function getInfoHistory() external view returns (InfoEntry[] memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { IssuerState, InfoEntry } from "../shared/Structs.sol";

interface IIssuer {
    function setInfo(string memory info) external;
    function getState() external view returns (IssuerState memory);
    function isWalletApproved(address _wallet) external view returns (bool);
    function getInfoHistory() external view returns (InfoEntry[] memory);
}

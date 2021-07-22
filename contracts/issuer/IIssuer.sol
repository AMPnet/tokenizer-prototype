// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../shared/Structs.sol";

interface IIssuer {
    function setInfo(string memory info) external;
    function getState() external view returns (Structs.IssuerState memory);
    function isWalletApproved(address _wallet) external view returns (bool);
    function getInfoHistory() external view returns (Structs.InfoEntry[] memory);
}

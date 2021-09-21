// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IVersioned.sol";
import "./Structs.sol";

interface IIssuerCommon is IVersioned {

    // WRITE
    function setInfo(string memory info) external;
    
    // READ
    function commonState() external view returns (Structs.IssuerCommonState memory);

}

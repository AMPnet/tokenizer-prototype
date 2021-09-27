// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../shared/IIssuerCommon.sol";
import "../shared/Structs.sol";

interface IIssuer is IIssuerCommon {

    // Write

    function changeOwnership(address newOwner) external;

    // Read
    
    function getState() external view returns (Structs.IssuerState memory);
    function getInfoHistory() external view returns (Structs.InfoEntry[] memory);
    function getWalletRecords() external view returns (Structs.WalletRecord[] memory);

}

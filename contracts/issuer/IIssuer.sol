// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../shared/IIssuerCommon.sol";
import "../shared/Structs.sol";

interface IIssuer is IIssuerCommon {

    // Write

    function approveWallet(address wallet) external;
    function suspendWallet(address wallet) external;
    function changeOwnership(address newOwner) external;
    function changeWalletApprover(address newWalletApprover) external;

    // Read
    
    function getState() external view returns (Structs.IssuerState memory);
    function isWalletApproved(address _wallet) external view returns (bool);
    function getInfoHistory() external view returns (Structs.InfoEntry[] memory);
    function getWalletRecords() external view returns (Structs.WalletRecord[] memory);

}

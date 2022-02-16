// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../shared/Structs.sol";
import "../shared/IAssetCommon.sol";

interface IAssetTransferable is IAssetCommon {

    // Write
    
    function approveCampaign(address campaign) external;
    function suspendCampaign(address campaign) external;
    function changeOwnership(address newOwner) external;
    function setWhitelistRequiredForRevenueClaim(bool whitelistRequired) external;
    function setWhitelistRequiredForLiquidationClaim(bool whitelistRequired) external;
    function setIssuerStatus(bool status) external;
    function liquidate() external;
    function claimLiquidationShare(address investor) external;
    function migrateApxRegistry(address newRegistry) external;

    // Read

    function getState() external view returns (Structs.AssetTransferableState memory);
    function getInfoHistory() external view returns (Structs.InfoEntry[] memory);
    function getCampaignRecords() external view returns (Structs.WalletRecord[] memory);
    function getSellHistory() external view returns (Structs.TokenSaleInfo[] memory);
    
}

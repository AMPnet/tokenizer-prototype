// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../shared/Structs.sol";

interface IAsset {

    // Write
    
    function lockTokens(address mirroredToken, uint256 amount) external;
    function unlockTokens(address wallet, uint256 amount) external;
    function approveCampaign(address campaign) external;
    function suspendCampaign(address campaign) external;
    function changeOwnership(address newOwner) external;
    function setInfo(string memory info) external;
    function setWhitelistRequiredForRevenueClaim(bool whitelistRequired) external;
    function setWhitelistRequiredForLiquidationClaim(bool whitelistRequired) external;
    function setIssuerStatus(bool status) external;
    function finalizeSale() external;
    function liquidate(address[] memory mirroredTokens) external;
    function liquidateMirrored(address mirroredToken) external;
    function claimLiquidationShare(address investor) external;
    function snapshot() external returns (uint256);
    function migrateApxRegistry(address newRegistry) external;

    // Read

    function totalShares() external view returns (uint256);
    function getDecimals() external view returns (uint256);
    function priceDecimalsPrecision() external view returns (uint256);
    function getState() external view returns (Structs.AssetState memory);
    function getInfoHistory() external view returns (Structs.InfoEntry[] memory);
    function getCampaignRecords() external view returns (Structs.WalletRecord[] memory);
    function getSellHistory() external view returns (Structs.TokenSaleInfo[] memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../tokens/erc20/IToken.sol";
import "../shared/Structs.sol";
import "../shared/IAssetCommon.sol";

interface IAsset is IAssetCommon {

    // Write
    
    function freezeTransfer() external;
    function lockTokens(uint256 amount) external;
    function unlockTokens(address wallet, uint256 amount) external;
    function setCampaignState(address campaign, bool approved) external;
    function changeOwnership(address newOwner) external;
    function setWhitelistFlags(bool whitelistRequiredForRevenueClaim, bool whitelistRequiredForLiquidationClaim) external;
    function setIssuerStatus(bool status) external;
    function liquidate() external;
    function claimLiquidationShare(address investor) external;
    function snapshot() external returns (uint256);
    function migrateApxRegistry(address newRegistry) external;

    // Read

    function getState() external view returns (Structs.AssetState memory);
    function getInfoHistory() external view returns (Structs.InfoEntry[] memory);
    function getSellHistory() external view returns (Structs.TokenSaleInfo[] memory);
    
}

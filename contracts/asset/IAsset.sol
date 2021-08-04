// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../shared/Structs.sol";

interface IAsset {

    // Write

    function approveCampaign(address campaign) external;
    function suspendCampaign(address campaign) external;
    function changeOwnership(address newOwner) external;
    function setInfo(string memory info) external;
    function setWhitelistRequiredForTransfer(bool whitelistRequiredForTransfer) external;
    function setIssuerStatus(bool status) external;
    function setMirroredToken(address token) external;
    function convertFromMirrored() external;
    function finalizeSale(uint256 tokenAmount, uint256 tokenValue) external;
    function liquidate() external;
    function claimLiquidationShare(address campaign, address investor) external;
    function snapshot() external returns (uint256);

    // Read

    function totalShares() external view returns (uint256);
    function getDecimals() external view returns (uint256);
    function getState() external view returns (Structs.AssetState memory);
    function getInfoHistory() external view returns (Structs.InfoEntry[] memory);
    function getCampaignRecords() external view returns (Structs.WalletRecord[] memory);
    function getSellHistory() external view returns (Structs.TokenSaleInfo[] memory);

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../tokens/erc20/IToken.sol";
import "../shared/Structs.sol";
import "../shared/IAssetCommon.sol";

interface IAssetSimple is IAssetCommon {

    // Write
    
    function setCampaignState(address campaign, bool approved) external;
    function changeOwnership(address newOwner) external;
    function setIssuerStatus(bool status) external;

    // Read

    function getState() external view returns (Structs.AssetSimpleState memory);
    function getInfoHistory() external view returns (Structs.InfoEntry[] memory);
    function getSellHistory() external view returns (Structs.TokenSaleInfo[] memory);
    
}

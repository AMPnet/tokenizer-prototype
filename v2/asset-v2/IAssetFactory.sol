// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { AssetFundingState } from "../shared/Enums.sol";

interface IAssetFactory {
    function create(
        address creator,
        address issuer,
        AssetFundingState fundingState,
        uint256 initialTokenSupply,
        uint256 initialPricePerToken,
        string memory name,
        string memory symbol,
        string memory info
    ) external returns (address);
    
    function getInstances() external view returns (address[] memory);
}

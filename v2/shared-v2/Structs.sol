// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../asset-v2/IAsset.sol";

struct CfManagerState {
    uint256 id;
    address owner;
    IAsset asset;
    uint256 initialPricePerToken;
    uint256 minInvestment;
    uint256 maxInvestment;
    uint256 endsAt;
    bool finalized;
    string info;
}

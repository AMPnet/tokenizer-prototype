// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../issuer/IIssuer.sol";
import "../asset/IAsset.sol";
import "./IGlobalRegistry.sol";
import { AssetFundingState } from "../shared/Enums.sol";

struct AssetState {
    uint256 id;
    address owner;
    uint256 initialTokenSupply;
    bool whitelistRequiredForTransfer;
    IIssuer issuer;
    string info;
    string name;
    string symbol;
}

struct IssuerState {
    uint256 id;
    address owner;
    address stablecoin;
    address walletApprover;
    string info;
}

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

struct CfManagerSoftcapState {
    uint256 id;
    address owner;
    IAsset asset;
    uint256 initialPricePerToken;
    uint256 softCap;
    bool whitelistRequired;
    bool finalized;
    bool cancelled;
    uint256 totalClaimableTokens;
    uint256 totalInvestorsCount;
    uint256 totalClaimsCount;
    string info;
}

struct PayoutManagerState {
    uint256 id;
    address owner;
    IAsset asset;
    string info;
}

struct InfoEntry {
    string info;
    uint256 timestamp;
}

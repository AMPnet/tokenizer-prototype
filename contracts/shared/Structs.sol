// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../issuer/IIssuer.sol";
import "../asset/IAsset.sol";
import "./IGlobalRegistry.sol";
import { AssetFundingState } from "../shared/Enums.sol";

struct AssetState {
    uint256 id;
    address creator;
    uint256 initialTokenSupply;
    uint256 initialPricePerToken;
    IIssuer issuer;
    AssetFundingState fundingState;
    string info;
    string name;
    string symbol;
}

struct IssuerState {
    uint256 id;
    address owner;
    address stablecoin;
    IGlobalRegistry registry;
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

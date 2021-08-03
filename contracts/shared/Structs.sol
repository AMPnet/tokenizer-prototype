// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Structs {

    struct TokenSaleInfo {
        address cfManager;
        uint256 tokenAmount;
        uint256 tokenValue;
        uint256 timestamp;
    }

    struct AssetState {
        uint256 id;
        address contractAddress;
        address owner;
        address mirroredToken;
        uint256 initialTokenSupply;
        bool whitelistRequiredForTransfer;
        bool assetApprovedByIssuer;
        address issuer;
        string info;
        string name;
        string symbol;
        uint256 totalAmountRaised;
        uint256 totalTokensSold;
        bool liquidated;
    }

    struct IssuerState {
        uint256 id;
        address contractAddress;
        address owner;
        address stablecoin;
        address walletApprover;
        string info;
    }

    struct CfManagerSoftcapState {
        uint256 id;
        address contractAddress;
        address owner;
        address asset;
        uint256 tokenPrice;
        uint256 softCap;
        bool whitelistRequired;
        bool finalized;
        bool cancelled;
        uint256 totalClaimableTokens;
        uint256 totalInvestorsCount;
        uint256 totalClaimsCount;
        uint256 totalFundsRaised;
        string info;
    }

    struct PayoutManagerState {
        uint256 id;
        address owner;
        address asset;
        string info;
    }

    struct InfoEntry {
        string info;
        uint256 timestamp;
    }
    
    struct WalletRecord {
        address wallet;
        bool whitelisted;
    }
    
}

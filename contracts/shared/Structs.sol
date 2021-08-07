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
        string ansName;
        uint256 ansId;
        address createdBy;
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
        uint256 liquidationTimestamp;
        uint256 liquidationSnapshotId;
        uint256 liquidationFundsClaimed;
    }

    struct IssuerState {
        uint256 id;
        address contractAddress;
        string ansName;
        address createdBy;
        address owner;
        address stablecoin;
        address walletApprover;
        string info;
    }

    struct CfManagerSoftcapState {
        uint256 id;
        address contractAddress;
        string ansName;
        uint256 ansId;
        address createdBy;
        address owner;
        address asset;
        address issuer;
        uint256 tokenPrice;
        uint256 softCap;
        uint256 minInvestment;
        uint256 maxInvestment;
        bool whitelistRequired;
        bool finalized;
        bool cancelled;
        uint256 totalClaimableTokens;
        uint256 totalInvestorsCount;
        uint256 totalClaimsCount;
        uint256 totalFundsRaised;
        uint256 totalTokensSold;
        uint256 totalTokensBalance;
        string info;
    }

    struct PayoutManagerState {
        uint256 id;
        address contractAddress;
        string ansName;
        uint256 ansId;
        address createdBy;
        address owner;
        address asset;
        uint256 totalPayoutsCreated;
        uint256 totalPayoutsAmount;
        string info;
    }

    struct Payout {
        uint256 snapshotId;
        string description;
        uint256 amount;
        uint256 totalReleased;
        uint256 totalClaimsCount;
        uint256 ignoredAmount;
        address[] ignoredWallets;
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

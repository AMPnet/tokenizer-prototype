// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Structs {

    struct TokenSaleInfo {
        address cfManager;
        uint256 tokenAmount;
        uint256 tokenValue;
        uint256 timestamp;
    }

    struct AssetRecord {
        address originalToken;
        address mirroredToken;
        bool exists;
        bool state;
        uint256 stateUpdatedAt;
        uint256 price;
        uint256 pricePrecision;
        uint256 priceUpdatedAt;
        uint256 priceValidUntil;
        address priceProvider;
    }

    struct TokenPriceRecord {
        uint256 price;
        uint256 updatedAtTimestamp;
        uint256 validUntilTimestamp;
        uint256 capturedSupply;
        address provider;
    }

    struct AssetTransferableFactoryParams {
        address creator;
        address issuer;
        address apxRegistry;
        string ansName;
        uint256 initialTokenSupply;
        bool whitelistRequiredForRevenueClaim;
        bool whitelistRequiredForLiquidationClaim;
        string name;
        string symbol;
        string info;
        address childChainManager;
    }
    
    struct AssetConstructorParams {
        uint256 id;
        address owner;
        address issuer;
        address apxRegistry;
        string ansName;
        uint256 ansId;
        uint256 initialTokenSupply;
        bool whitelistRequiredForRevenueClaim;
        bool whitelistRequiredForLiquidationClaim;
        string name;
        string symbol;
        string info;
    }

    struct AssetTransferableConstructorParams {
        uint256 id;
        address owner;
        address issuer;
        address apxRegistry;
        string ansName;
        uint256 ansId;
        uint256 initialTokenSupply;
        bool whitelistRequiredForRevenueClaim;
        bool whitelistRequiredForLiquidationClaim;
        string name;
        string symbol;
        string info;
        address childChainManager;
    }

    struct AssetState {
        uint256 id;
        address contractAddress;
        string ansName;
        uint256 ansId;
        address createdBy;
        address owner;
        uint256 initialTokenSupply;
        bool whitelistRequiredForRevenueClaim;
        bool whitelistRequiredForLiquidationClaim;
        bool assetApprovedByIssuer;
        address issuer;
        address apxRegistry;
        string info;
        string name;
        string symbol;
        uint256 totalAmountRaised;
        uint256 totalTokensSold;
        uint256 highestTokenSellPrice;
        uint256 totalTokensLocked;
        uint256 totalTokensLockedAndLiquidated;
        bool liquidated;
        uint256 liquidationFundsTotal;
        uint256 liquidationTimestamp;
        uint256 liquidationFundsClaimed;
    }

    struct AssetTransferableState {
        uint256 id;
        address contractAddress;
        string ansName;
        uint256 ansId;
        address createdBy;
        address owner;
        uint256 initialTokenSupply;
        bool whitelistRequiredForRevenueClaim;
        bool whitelistRequiredForLiquidationClaim;
        bool assetApprovedByIssuer;
        address issuer;
        address apxRegistry;
        string info;
        string name;
        string symbol;
        uint256 totalAmountRaised;
        uint256 totalTokensSold;
        uint256 highestTokenSellPrice;
        bool liquidated;
        uint256 liquidationFundsTotal;
        uint256 liquidationTimestamp;
        uint256 liquidationFundsClaimed;
        address childChainManager;
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
        address assetFactory;
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
        address assetFactory;
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

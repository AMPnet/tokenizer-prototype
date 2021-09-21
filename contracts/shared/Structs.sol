// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Structs {

    struct IssuerCommonState {
        string flavor;
        string version;
        address contractAddress;
        address owner;
        string info;
    }

    struct AssetCommonState {
        string flavor;
        string version;
        address contractAddress;
        address owner;
        string info;
        string name;
        string symbol;
        uint256 totalSupply;
        uint256 decimals;
        address issuer;
    }

    struct AssetCommonStateWithName {
        Structs.AssetCommonState asset;
        string mappedName;
    }

    struct CampaignCommonState {
        string flavor;
        string version;
        address contractAddress;
        address owner;
        string info;
        address asset;
        uint256 softCap;
        bool finalized;
        bool canceled;
        uint256 pricePerToken;
        uint256 fundsRaised;
        uint256 tokensSold;
    }

    struct CampaignCommonStateWithName {
        CampaignCommonState campaign;
        string mappedName;
    }

    struct CampaignCommonStateWithNameAndInvestment {
        CampaignCommonState campaign;
        string mappedName;
        uint256 tokenAmount;
        uint256 tokenValue;
    }

    struct IssuerCommonStateWithName {
        string flavor;
        string version;
        address contractAddress;
        address owner;
        string info;
        string mappedName;
    }
    
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
        uint256 priceUpdatedAt;
        uint256 priceValidUntil;
        uint256 capturedSupply;
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
        string mappedName;
        address nameRegistry;
        uint256 initialTokenSupply;
        bool whitelistRequiredForRevenueClaim;
        bool whitelistRequiredForLiquidationClaim;
        string name;
        string symbol;
        string info;
        address childChainManager;
    }

    struct AssetFactoryParams {
        address creator;
        address issuer;
        address apxRegistry;
        address nameRegistry;
        string mappedName;
        uint256 initialTokenSupply;
        bool transferable;
        bool whitelistRequiredForRevenueClaim;
        bool whitelistRequiredForLiquidationClaim;
        string name;
        string symbol;
        string info;
    }
    
    struct AssetConstructorParams {
        string flavor;
        string version;
        address owner;
        address issuer;
        address apxRegistry;
        uint256 initialTokenSupply;
        bool transferable;
        bool whitelistRequiredForRevenueClaim;
        bool whitelistRequiredForLiquidationClaim;
        string name;
        string symbol;
        string info;
    }

    struct AssetTransferableConstructorParams {
        string flavor;
        string version;
        address owner;
        address issuer;
        address apxRegistry;
        uint256 initialTokenSupply;
        bool whitelistRequiredForRevenueClaim;
        bool whitelistRequiredForLiquidationClaim;
        string name;
        string symbol;
        string info;
        address childChainManager;
    }

    struct AssetState {
        string flavor;
        string version;
        address contractAddress;
        address owner;
        uint256 initialTokenSupply;
        bool transferable;
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
        string flavor;
        string version;
        address contractAddress;
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
        string flavor;
        string version;
        address contractAddress;
        address owner;
        address stablecoin;
        address walletApprover;
        string info;
    }

    struct CfManagerSoftcapState {
        string flavor;
        string version;
        address contractAddress;
        address owner;
        address asset;
        address issuer;
        uint256 tokenPrice;
        uint256 softCap;
        uint256 minInvestment;
        uint256 maxInvestment;
        bool whitelistRequired;
        bool finalized;
        bool canceled;
        uint256 totalClaimableTokens;
        uint256 totalInvestorsCount;
        uint256 totalClaimsCount;
        uint256 totalFundsRaised;
        uint256 totalTokensSold;
        uint256 totalTokensBalance;
        string info;
    }

    struct PayoutManagerState {
        string flavor;
        string version;
        address contractAddress;
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

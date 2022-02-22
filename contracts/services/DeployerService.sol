// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../asset/IAsset.sol";
import "../asset/IAssetFactory.sol";
import "../asset-transferable/IAssetTransferable.sol";
import "../asset-transferable/IAssetTransferableFactory.sol";
import "../asset-simple/IAssetSimple.sol";
import "../asset-simple/IAssetSimpleFactory.sol";
import "../issuer/IIssuer.sol";
import "../issuer/IIssuerFactory.sol";
import "../managers/crowdfunding-softcap/ICfManagerSoftcap.sol";
import "../managers/crowdfunding-softcap/ICfManagerSoftcapFactory.sol";
import "../managers/crowdfunding-softcap-vesting/ICfManagerSoftcapVesting.sol";
import "../managers/crowdfunding-softcap-vesting/ICfManagerSoftcapVestingFactory.sol";
import "../tokens/erc20/IToken.sol";
import "../shared/IVersioned.sol";

interface IDeployerService is IVersioned {

    event DeployIssuerAssetCampaign(
        address caller,
        address issuer,
        address asset,
        address campaign,
        uint256 timestamp
    );
    event DeployAssetCampaign(
        address caller,
        address asset,
        address campaign,
        uint256 timestamp
    );
    event DeployIssuerAssetTransferableCampaign(
        address caller,
        address issuer,
        address asset,
        address campaign,
        uint256 timestamp
    );
    event DeployAssetTransferableCampaign(
        address caller,
        address asset,
        address campaign,
        uint256 timestamp
    );

    struct DeployIssuerAssetCampaignRequest {
        IIssuerFactory issuerFactory;
        IAssetFactory assetFactory;
        ICfManagerSoftcapFactory cfManagerSoftcapFactory;
        address issuerOwner;
        string issuerMappedName;
        address issuerStablecoin;
        address issuerWalletApprover;
        string issuerInfo;
        address assetOwner;
        string assetMappedName;
        uint256 assetInitialTokenSupply;
        bool assetWhitelistRequiredForRevenueClaim;
        bool assetWhitelistRequiredForLiquidationClaim;
        string assetName;
        string assetSymbol;
        string assetInfo;
        address cfManagerOwner;
        string cfManagerMappedName;
        uint256 cfManagerPricePerToken;
        uint256 cfManagerSoftcap;
        uint256 cfManagerSoftcapMinInvestment;
        uint256 cfManagerSoftcapMaxInvestment;
        uint256 cfManagerTokensToSellAmount;
        bool cfManagerWhitelistRequired;
        string cfManagerInfo;
        address apxRegistry;
        address nameRegistry;
        address feeManager;
    }

    struct DeployAssetCampaignRequest {
        IAssetFactory assetFactory;
        ICfManagerSoftcapFactory cfManagerSoftcapFactory;
        address issuer;
        address assetOwner;
        string assetMappedName;
        uint256 assetInitialTokenSupply;
        bool assetWhitelistRequiredForRevenueClaim;
        bool assetWhitelistRequiredForLiquidationClaim;
        string assetName;
        string assetSymbol;
        string assetInfo;
        address cfManagerOwner;
        string cfManagerMappedName;
        uint256 cfManagerPricePerToken;
        uint256 cfManagerSoftcap;
        uint256 cfManagerSoftcapMinInvestment;
        uint256 cfManagerSoftcapMaxInvestment;
        uint256 cfManagerTokensToSellAmount;
        bool cfManagerWhitelistRequired;
        string cfManagerInfo;
        address apxRegistry;
        address nameRegistry;
        address feeManager;
    }

    struct DeployIssuerAssetTransferableCampaignRequest {
        IIssuerFactory issuerFactory;
        IAssetTransferableFactory assetTransferableFactory;
        ICfManagerSoftcapFactory cfManagerSoftcapFactory;
        address issuerOwner;
        string issuerMappedName;
        address issuerStablecoin;
        address issuerWalletApprover;
        string issuerInfo;
        address assetOwner;
        string assetMappedName;
        uint256 assetInitialTokenSupply;
        bool assetWhitelistRequiredForRevenueClaim;
        bool assetWhitelistRequiredForLiquidationClaim;
        string assetName;
        string assetSymbol;
        string assetInfo;
        address cfManagerOwner;
        string cfManagerMappedName;
        uint256 cfManagerPricePerToken;
        uint256 cfManagerSoftcap;
        uint256 cfManagerSoftcapMinInvestment;
        uint256 cfManagerSoftcapMaxInvestment;
        uint256 cfManagerTokensToSellAmount;
        bool cfManagerWhitelistRequired;
        string cfManagerInfo;
        address apxRegistry;
        address nameRegistry;
        address feeManager;
    }

    struct DeployAssetTransferableCampaignRequest {
        IAssetTransferableFactory assetTransferableFactory;
        ICfManagerSoftcapFactory cfManagerSoftcapFactory;
        address issuer;
        address assetOwner;
        string assetMappedName;
        uint256 assetInitialTokenSupply;
        bool assetWhitelistRequiredForRevenueClaim;
        bool assetWhitelistRequiredForLiquidationClaim;
        string assetName;
        string assetSymbol;
        string assetInfo;
        address cfManagerOwner;
        string cfManagerMappedName;
        uint256 cfManagerPricePerToken;
        uint256 cfManagerSoftcap;
        uint256 cfManagerSoftcapMinInvestment;
        uint256 cfManagerSoftcapMaxInvestment;
        uint256 cfManagerTokensToSellAmount;
        bool cfManagerWhitelistRequired;
        string cfManagerInfo;
        address apxRegistry;
        address nameRegistry;
        address feeManager;
    }

    struct DeployAssetSimpleCampaignVestingRequest {
        IAssetSimpleFactory assetSimpleFactory;
        ICfManagerSoftcapVestingFactory cfManagerSoftcapVestingFactory;
        address issuer;
        address assetOwner;
        string assetMappedName;
        uint256 assetInitialTokenSupply;
        string assetName;
        string assetSymbol;
        string assetInfo;
        address cfManagerOwner;
        string cfManagerMappedName;
        uint256 cfManagerPricePerToken;
        uint256 cfManagerSoftcap;
        uint256 cfManagerSoftcapMinInvestment;
        uint256 cfManagerSoftcapMaxInvestment;
        uint256 cfManagerTokensToSellAmount;
        bool cfManagerWhitelistRequired;
        string cfManagerInfo;
        address nameRegistry;
        address feeManager;
    }


    function deployIssuerAssetCampaign(DeployIssuerAssetCampaignRequest memory request) external;
    function deployAssetCampaign(DeployAssetCampaignRequest memory request) external;
    function deployIssuerAssetTransferableCampaign(DeployIssuerAssetTransferableCampaignRequest memory request) external;
    function deployAssetTransferableCampaign(DeployAssetTransferableCampaignRequest memory request) external;
    function deployAssetSimpleCampaignVesting(DeployAssetSimpleCampaignVestingRequest memory request) external;

}

contract DeployerService is IDeployerService {

    string constant public FLAVOR = "DeployerServiceV1";
    string constant public VERSION = "1.0.30";

    function flavor() external pure override returns (string memory) { return FLAVOR; }
    function version() external pure override returns (string memory) { return VERSION; } 
 
    function deployIssuerAssetCampaign(DeployIssuerAssetCampaignRequest memory request) external override {
        // Deploy contracts
        IIssuer issuer = IIssuer(request.issuerFactory.create(
            address(this),
            request.issuerMappedName,
            request.issuerStablecoin,
            address(this),
            request.issuerInfo,
            request.nameRegistry
        ));
        IAsset asset = IAsset(request.assetFactory.create(
            Structs.AssetFactoryParams(
                address(this),
                address(issuer),
                request.apxRegistry,
                request.nameRegistry,
                request.assetMappedName,
                request.assetInitialTokenSupply,
                true,
                request.assetWhitelistRequiredForRevenueClaim,
                request.assetWhitelistRequiredForLiquidationClaim,
                request.assetName,
                request.assetSymbol,
                request.assetInfo
            )
        ));
        ICfManagerSoftcap campaign = ICfManagerSoftcap(request.cfManagerSoftcapFactory.create(
            address(this),
            request.cfManagerMappedName,
            address(asset),
            request.cfManagerPricePerToken,
            request.cfManagerSoftcap,
            request.cfManagerSoftcapMinInvestment,
            request.cfManagerSoftcapMaxInvestment,
            request.cfManagerWhitelistRequired,
            request.cfManagerInfo,
            request.nameRegistry,
            request.feeManager
        ));

        // Whitelist owners
        issuer.approveWallet(request.issuerOwner);
        issuer.approveWallet(request.assetOwner);
        issuer.approveWallet(request.cfManagerOwner);
        
        // Transfer tokens to sell to the campaign, transfer the rest to the asset owner's wallet
        uint256 tokensToSell = request.cfManagerTokensToSellAmount;
        uint256 tokensToKeep = IERC20(address(asset)).totalSupply() - tokensToSell;
        IERC20 assetERC20 = IERC20(address(asset));
        assetERC20.transfer(address(campaign), tokensToSell);
        assetERC20.transfer(request.assetOwner, tokensToKeep);
        
        // Transfer ownerships from address(this) to the actual owner wallets
        issuer.changeWalletApprover(request.issuerWalletApprover);
        issuer.changeOwnership(request.issuerOwner);
        asset.changeOwnership(request.assetOwner);
        campaign.changeOwnership(request.cfManagerOwner);

        emit DeployIssuerAssetCampaign(msg.sender, address(issuer), address(asset), address(campaign), block.timestamp);
    }

    function deployAssetCampaign(DeployAssetCampaignRequest memory request) external override {
        // Deploy contracts
        IAsset asset = IAsset(request.assetFactory.create(
            Structs.AssetFactoryParams(
                address(this),
                request.issuer,
                request.apxRegistry,
                request.nameRegistry,
                request.assetMappedName,
                request.assetInitialTokenSupply,
                true,
                request.assetWhitelistRequiredForRevenueClaim,
                request.assetWhitelistRequiredForLiquidationClaim,
                request.assetName,
                request.assetSymbol,
                request.assetInfo
            )
        ));
        ICfManagerSoftcap campaign = ICfManagerSoftcap(request.cfManagerSoftcapFactory.create(
            address(this),
            request.cfManagerMappedName,
            address(asset),
            request.cfManagerPricePerToken,
            request.cfManagerSoftcap,
            request.cfManagerSoftcapMinInvestment,
            request.cfManagerSoftcapMaxInvestment,
            request.cfManagerWhitelistRequired,
            request.cfManagerInfo,
            request.nameRegistry,
            request.feeManager
        ));

        // Transfer tokens to sell to the campaign, transfer the rest to the asset owner's wallet
        uint256 tokensToSell = request.cfManagerTokensToSellAmount;
        uint256 tokensToKeep = IERC20(address(asset)).totalSupply() - tokensToSell;
        IERC20 assetERC20 = IERC20(address(asset));
        assetERC20.transfer(address(campaign), tokensToSell);
        assetERC20.transfer(request.assetOwner, tokensToKeep);

        // Transfer ownerships from address(this) to the actual owner wallets
        asset.freezeTransfer();
        asset.changeOwnership(request.assetOwner);
        campaign.changeOwnership(request.cfManagerOwner);

        emit DeployAssetCampaign(msg.sender, address(asset), address(campaign), block.timestamp);
    }

    function deployIssuerAssetTransferableCampaign(
        DeployIssuerAssetTransferableCampaignRequest memory request
    ) external override {
        // Deploy contracts
        IIssuer issuer = IIssuer(request.issuerFactory.create(
            address(this),
            request.issuerMappedName,
            request.issuerStablecoin,
            address(this),
            request.issuerInfo,
            request.nameRegistry
        ));
        IAssetTransferable asset = IAssetTransferable(
            request.assetTransferableFactory.create(
                Structs.AssetTransferableFactoryParams(
                    address(this),
                    address(issuer),
                    request.apxRegistry,
                    request.assetMappedName,
                    request.nameRegistry,
                    request.assetInitialTokenSupply,
                    request.assetWhitelistRequiredForRevenueClaim,
                    request.assetWhitelistRequiredForLiquidationClaim,
                    request.assetName,
                    request.assetSymbol,
                    request.assetInfo
                )
            )
        );

        ICfManagerSoftcap campaign = ICfManagerSoftcap(request.cfManagerSoftcapFactory.create(
            address(this),
            request.cfManagerMappedName,
            address(asset),
            request.cfManagerPricePerToken,
            request.cfManagerSoftcap,
            request.cfManagerSoftcapMinInvestment,
            request.cfManagerSoftcapMaxInvestment,
            request.cfManagerWhitelistRequired,
            request.cfManagerInfo,
            request.nameRegistry,
            request.feeManager
        ));

        // Whitelist issuer owner
        issuer.approveWallet(request.issuerOwner);
        
        // Transfer tokens to sell to the campaign, transfer the rest to the asset owner's wallet
        uint256 tokensToSell = request.cfManagerTokensToSellAmount;
        uint256 tokensToKeep = IERC20(address(asset)).totalSupply() - tokensToSell;
        IERC20 assetERC20 = IERC20(address(asset));
        assetERC20.transfer(address(campaign), tokensToSell);
        assetERC20.transfer(request.assetOwner, tokensToKeep);
        
        // Transfer ownerships from address(this) to the actual owner wallets
        issuer.changeWalletApprover(request.issuerWalletApprover);
        issuer.changeOwnership(request.issuerOwner);
        asset.changeOwnership(request.assetOwner);
        campaign.changeOwnership(request.cfManagerOwner);

        emit DeployIssuerAssetTransferableCampaign(
            msg.sender,
            address(issuer),
            address(asset),
            address(campaign),
            block.timestamp
        );
    }

    function deployAssetTransferableCampaign(DeployAssetTransferableCampaignRequest memory request) external override {
        // Deploy contracts
        IAssetTransferable asset = IAssetTransferable(
            request.assetTransferableFactory.create(
                Structs.AssetTransferableFactoryParams(
                    address(this),
                    request.issuer,
                    request.apxRegistry,
                    request.assetMappedName,
                    request.nameRegistry,
                    request.assetInitialTokenSupply,
                    request.assetWhitelistRequiredForRevenueClaim,
                    request.assetWhitelistRequiredForLiquidationClaim,
                    request.assetName,
                    request.assetSymbol,
                    request.assetInfo
                )
        ));
        ICfManagerSoftcap campaign = ICfManagerSoftcap(request.cfManagerSoftcapFactory.create(
            address(this),
            request.cfManagerMappedName,
            address(asset),
            request.cfManagerPricePerToken,
            request.cfManagerSoftcap,
            request.cfManagerSoftcapMinInvestment,
            request.cfManagerSoftcapMaxInvestment,
            request.cfManagerWhitelistRequired,
            request.cfManagerInfo,
            request.nameRegistry,
            request.feeManager
        ));

        // Transfer tokens to sell to the campaign, transfer the rest to the asset owner's wallet
        uint256 tokensToSell = request.cfManagerTokensToSellAmount;
        uint256 tokensToKeep = IERC20(address(asset)).totalSupply() - tokensToSell;
        IERC20 assetERC20 = IERC20(address(asset));
        assetERC20.transfer(address(campaign), tokensToSell);
        assetERC20.transfer(request.assetOwner, tokensToKeep);

        // Transfer ownerships from address(this) to the actual owner wallets
        asset.changeOwnership(request.assetOwner);
        campaign.changeOwnership(request.cfManagerOwner);

        emit DeployAssetCampaign(msg.sender, address(asset), address(campaign), block.timestamp);
    }

    function deployAssetSimpleCampaignVesting(DeployAssetSimpleCampaignVestingRequest memory request) external override {
        // Deploy contracts
        IAssetSimple asset = IAssetSimple(
            request.assetSimpleFactory.create(
                Structs.AssetSimpleFactoryParams(
                    address(this),
                    request.issuer,
                    request.assetMappedName,
                    request.nameRegistry,
                    request.assetInitialTokenSupply,
                    request.assetName,
                    request.assetSymbol,
                    request.assetInfo
                )
            )
        );
        ICfManagerSoftcapVesting campaign = ICfManagerSoftcapVesting(request.cfManagerSoftcapVestingFactory.create(
            address(this),
            request.cfManagerMappedName,
            address(asset),
            request.cfManagerPricePerToken,
            request.cfManagerSoftcap,
            request.cfManagerSoftcapMinInvestment,
            request.cfManagerSoftcapMaxInvestment,
            request.cfManagerWhitelistRequired,
            request.cfManagerInfo,
            request.nameRegistry,
            request.feeManager
        ));

        // Transfer tokens to sell to the campaign, transfer the rest to the asset owner's wallet
        uint256 tokensToSell = request.cfManagerTokensToSellAmount;
        uint256 tokensToKeep = IERC20(address(asset)).totalSupply() - tokensToSell;
        IERC20 assetERC20 = IERC20(address(asset));
        assetERC20.transfer(address(campaign), tokensToSell);
        assetERC20.transfer(request.assetOwner, tokensToKeep);

        // Transfer ownerships from address(this) to the actual owner wallets
        asset.changeOwnership(request.assetOwner);
        campaign.changeOwnership(request.cfManagerOwner);

        emit DeployAssetCampaign(msg.sender, address(asset), address(campaign), block.timestamp);
    }

}

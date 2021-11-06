// @ts-ignore
import { ethers } from "hardhat";
import { Contract, Signer } from "ethers";
import * as helpers from "../util/helpers";
import * as deployerServiceUtil from "../util/deployer-service";
import { CfManagerSoftcap, CfManagerSoftcapVesting } from "../typechain";

export class TestData {

    //////// FACTORIES ////////
    issuerFactory: Contract;
    assetFactory: Contract;
    assetTransferableFactory: Contract;
    assetSimpleFactory: Contract;
    cfManagerFactory: Contract;
    cfManagerVestingFactory: Contract;
    snapshotDistributorFactory: Contract;

    //////// SERVICES ////////
    walletApproverService: Contract;
    deployerService: Contract;
    queryService: Contract;

    ////////// APX //////////
    apxRegistry: Contract;
    nameRegistry: Contract;

    //////// SIGNERS ////////
    deployer: Signer;
    assetManager: Signer;
    priceManager: Signer;
    walletApprover: Signer;
    issuerOwner: Signer;
    alice: Signer;
    jane: Signer;
    frank: Signer;
    mark: Signer;

    //////// CONTRACTS ////////
    stablecoin: Contract;
    issuer: Contract;
    asset: Contract;
    cfManager: CfManagerSoftcap;
    cfManagerVesting: CfManagerSoftcapVesting;

    //////// CONST ////////
    assetName = "Test Asset";
    assetTicker = "TSTA";
    assetAnsName = "test-asset";
    assetInfoHash = "asset-info-ipfs-hash";
    assetWhitelistRequiredForRevenueClaim = true;
    assetWhitelistRequiredForLiquidationClaim = true;
    assetTokenSupply = 300000;              // 300k tokens total supply
    campaignInitialPricePerToken = 10000;   // 1$ per token
    maxTokensToBeSold = 200000;             // 200k tokens to be sold at most (200k $$$ to be raised at most)
    campaignSoftCap = 100000;               // minimum $100k funds raised has to be reached for campaign to succeed
    campaignMinInvestment = 10000;          // $10k min investment per user
    campaignMaxInvestment = 400000;         // $200k max investment per user
    campaignWhitelistRequired = true;       // only whitelisted wallets can invest
    campaignAnsName = "test-campaign";
    campaignInfoHash = "campaign-info-ipfs-hash";
    childChainManager: string;

    async deploy() {
        const accounts: Signer[] = await ethers.getSigners();

        this.deployer        = accounts[0];
        this.assetManager    = accounts[1];
        this.priceManager    = accounts[2];
        this.walletApprover  = accounts[3];

        this.issuerOwner     = accounts[4];
        this.alice           = accounts[5];
        this.jane            = accounts[6];
        this.frank           = accounts[7];
        this.mark            = accounts[8];

        this.stablecoin = await helpers.deployStablecoin(this.deployer, "1000000000000");

        const factories = await helpers.deployFactories(this.deployer);
        this.issuerFactory = factories[0];
        this.assetFactory = factories[1];
        this.assetTransferableFactory = factories[2];
        this.assetSimpleFactory = factories[3];
        this.cfManagerFactory = factories[4];
        this.cfManagerVestingFactory = factories[5];
        this.snapshotDistributorFactory = factories[6];

        this.apxRegistry = await helpers.deployApxRegistry(
            this.deployer,
            await this.deployer.getAddress(),
            await this.assetManager.getAddress(),
            await this.priceManager.getAddress()
        );
        this.nameRegistry = await helpers.deployNameRegistry(
            this.deployer,
            await this.deployer.getAddress(),
            factories.map(factory => factory.address)
        );

        const walletApproverAddress = await this.walletApprover.getAddress();
        const services = await helpers.deployServices(
            this.deployer,
            walletApproverAddress,
            "0.001"
        );
        this.walletApproverService = services[0];
        this.deployerService = services[1];
        this.queryService = services[2];

        this.childChainManager = ethers.Wallet.createRandom().address;
    }

    async deployIssuerAssetTransferableCampaign() {
        //// Set the config for Issuer, Asset and Crowdfunding Campaign
        const issuerOwnerAddress = await this.issuerOwner.getAddress();

        //// Deploy the contracts with the provided config
        await this.deployIssuer()
        const contracts = await deployerServiceUtil.createAssetTransferableCampaign(
            this.issuer,
            issuerOwnerAddress,
            this.assetAnsName,
            this.assetTokenSupply,
            this.assetWhitelistRequiredForRevenueClaim,
            this.assetWhitelistRequiredForLiquidationClaim,
            this.assetName,
            this.assetTicker,
            this.assetInfoHash,
            issuerOwnerAddress,
            this.campaignAnsName,
            this.campaignInitialPricePerToken,
            this.campaignSoftCap,
            this.campaignMinInvestment,
            this.campaignMaxInvestment,
            this.maxTokensToBeSold,
            this.campaignWhitelistRequired,
            this.campaignInfoHash,
            this.apxRegistry.address,
            this.nameRegistry.address,
            this.childChainManager,
            this.assetTransferableFactory,
            this.cfManagerFactory,
            this.deployerService
        );
        this.asset = contracts[0];
        this.cfManager = contracts[1] as CfManagerSoftcap;
    }

    async deployIssuerAssetClassicCampaign() {
        const issuerOwnerAddress = await this.issuerOwner.getAddress();

        //// Deploy the contracts with the provided config
        await this.deployIssuer()
        const contracts = await deployerServiceUtil.createAssetCampaign(
            this.issuer,
            issuerOwnerAddress,
            this.assetAnsName,
            this.assetTokenSupply,
            this.assetWhitelistRequiredForRevenueClaim,
            this.assetWhitelistRequiredForLiquidationClaim,
            this.assetName,
            this.assetTicker,
            this.assetInfoHash,
            issuerOwnerAddress,
            this.campaignAnsName,
            this.campaignInitialPricePerToken,
            this.campaignSoftCap,
            this.campaignMinInvestment,
            this.campaignMaxInvestment,
            this.maxTokensToBeSold,
            this.campaignWhitelistRequired,
            this.campaignInfoHash,
            this.apxRegistry.address,
            this.nameRegistry.address,
            this.assetFactory,
            this.cfManagerFactory,
            this.deployerService
        );
        this.asset = contracts[0];
        this.cfManager = contracts[1] as CfManagerSoftcap;
    }

    async deployIssuerAssetSimpleCampaignVesting() {
        //// Set the config for Issuer, Asset and Crowdfunding Campaign
        const issuerOwnerAddress = await this.issuerOwner.getAddress();

        //// Deploy the contracts with the provided config
        await this.deployIssuer()
        const contracts = await deployerServiceUtil.createAssetSimpleCampaignVesting(
            this.issuer,
            issuerOwnerAddress,
            this.assetAnsName,
            this.assetTokenSupply,
            this.assetName,
            this.assetTicker,
            this.assetInfoHash,
            issuerOwnerAddress,
            this.campaignAnsName,
            this.campaignInitialPricePerToken,
            this.campaignSoftCap,
            this.campaignMinInvestment,
            this.campaignMaxInvestment,
            this.maxTokensToBeSold,
            this.campaignWhitelistRequired,
            this.campaignInfoHash,
            this.nameRegistry.address,
            this.assetSimpleFactory,
            this.cfManagerVestingFactory,
            this.deployerService
        );
        this.asset = contracts[0];
        this.cfManagerVesting = contracts[1] as CfManagerSoftcapVesting;
    }

    async deployIssuer() {
        const issuerAnsName = "test-issuer";
        const issuerInfoHash = "issuer-info-ipfs-hash";
        const issuerOwnerAddress = await this.issuerOwner.getAddress();
        this.issuer = await helpers.createIssuer(
            issuerOwnerAddress,
            issuerAnsName,
            this.stablecoin,
            this.walletApproverService.address,
            issuerInfoHash,
            this.issuerFactory,
            this.nameRegistry
        );
    }

    async liquidateAsset(liquidationFunds: number = 300000) {
        await this.stablecoin
            .transfer(await this.issuerOwner.getAddress(), ethers.utils.parseEther(liquidationFunds.toString()));
        await this.stablecoin.connect(this.assetManager)
            .approve(this.asset.address, ethers.utils.parseEther(liquidationFunds.toString()));
        await helpers
            .registerAsset(this.assetManager, this.apxRegistry, this.asset.address, this.asset.address);
        await helpers.updatePrice(this.priceManager, this.apxRegistry, this.asset, 1, 60);
        await helpers.liquidate(this.issuerOwner, this.asset, this.stablecoin, liquidationFunds);
    }
}

import { ethers } from "hardhat";
import { Contract } from "ethers";
import * as helpers from "../util/helpers";

async function main() {
    const accounts = await ethers.getSigners();
    const network = await ethers.provider.getNetwork();
    const deployer = accounts[0];
    const deployerAddress = await deployer.getAddress();
    console.log(`Network name: ${network.name}`);
    console.log(`Chain Id: ${network.chainId}`);
    console.log(`Deployer address (accounts[0]): ${deployerAddress}`);

    const stablecoin: Contract = (process.env.STABLECOIN) ? 
        await ethers.getContractAt("USDC", process.env.STABLECOIN) :
        await helpers.deployStablecoin(deployer, "10000000000");
    
    const issuerFactory: Contract = (process.env.ISSUER_FACTORY) ?
        await ethers.getContractAt("IssuerFactory", process.env.ISSUER_FACTORY) :
        await helpers.deployIssuerFactory(deployer);

    const assetFactory: Contract = (process.env.ASSET_FACTORY) ?
        await ethers.getContractAt("AssetFactory", process.env.ASSET_FACTORY) :
        await helpers.deployAssetFactory(deployer);

    const cfManagerFactory: Contract = (process.env.CF_MANAGER_FACTORY) ?
        await ethers.getContractAt("CfManagerSoftcapFactory", process.env.CF_MANAGER_FACTORY) :
        await helpers.deployCfManagerFactory(deployer);

    const issuerOwner = process.env.ISSUER_OWNER || deployerAddress;
    const issuerWalletApprover = process.env.ISSUER_WALLET_APPROVER || issuerOwner;
    const issuerInfoIpfsHash = process.env.ISSUER_IPFS || "issuer-info-ipfs-hash";
    const issuer = (process.env.ISSUER) ?
        await ethers.getContractAt("Issuer", process.env.ISSUER) :
        await helpers.createIssuer(
            issuerOwner,
            stablecoin,
            issuerWalletApprover,
            issuerInfoIpfsHash,
            issuerFactory
        );

    const assetName = process.env.ASSET_NAME || "Test Asset";
    const assetSymbol = process.env.ASSET_SYMBOL || "$TSTA";
    const assetInfoIpfsHash = process.env.ASSET_IPFS || "asset-info-ipfs-hash";
    const assetSupply = Number(process.env.ASSET_SUPPLY) || 1000000;
    const assetOwnerAddress = process.env.ASSET_OWNER || issuerOwner;
    const transferWhitelistRequired = (process.env.ASSET_TRANSFER_WHITELIST_REQUIRED == "true") || false;
    const asset = (process.env.ASSET) ?
        await ethers.getContractAt("Asset", process.env.ASSET) :
        await helpers.createAsset(
            assetOwnerAddress,
            issuer,
            assetSupply,
            transferWhitelistRequired,
            assetName,
            assetSymbol,
            assetInfoIpfsHash,
            assetFactory
        );

    const campaignOwner = process.env.CAMPAIGN_OWNER || issuerOwner;
    const campaignPricePerToken = Number(process.env.CAMPAIGN_TOKEN_PRICE) || 10000; // ($1 default token price)
    const campaignSoftCap = Number(process.env.CAMPAIGN_SOFT_CAP) || 100000; // ($100k soft cap)
    const campaignInvestorWhitelistRequired = (process.env.CAMPAIGN_INVESTOR_WHITELIST_REQUIRED == "true") || false;
    const campaignInfoIpfsHash = process.env.CAMPAIGN_IPFS || "test-campaign-ipfs-hash";
    const campaign = (process.env.CAMPAIGN) ?
        await ethers.getContractAt("CfManagerSofctap", process.env.CAMPAIGN) :
        await helpers.createCfManager(
            campaignOwner,
            asset,
            campaignPricePerToken,
            campaignSoftCap,
            campaignInvestorWhitelistRequired,
            campaignInfoIpfsHash,
            cfManagerFactory
        );

    await campaign.deployed()
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });

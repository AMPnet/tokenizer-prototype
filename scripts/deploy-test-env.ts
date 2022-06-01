// @ts-ignore
import { ethers } from "hardhat";
import { Contract, constants } from "ethers";
import * as helpers from "../util/helpers";

async function main() {
    const accounts = await ethers.getSigners();
    const network = await ethers.provider.getNetwork();
    const deployer = accounts[0];
    const deployerAddress = await deployer.getAddress();
    const addressZero = constants.AddressZero;

    console.log(`Network name: ${network.name}`);
    console.log(`Chain Id: ${network.chainId}`);
    console.log(`Deployer address (accounts[0]): ${deployerAddress}`);
    console.log(`Deployer balance (accounts[0]):`, (await ethers.provider.getBalance(deployerAddress)).toString());

    const stablecoin: Contract = (process.env.STABLECOIN) ? 
        await ethers.getContractAt("USDC", process.env.STABLECOIN) :
        await helpers.deployStablecoin(deployer, "10000000000", 6);

    const apxRegistry: Contract = (process.env.APX_REGISTRY) ?
        await ethers.getContractAt("ApxAssetsRegistry", process.env.APX_REGISTRY) :
        await helpers.deployApxRegistry(
            deployer,
            process.env.APX_REGISTRY_MASTER_OWNER,
            process.env.APX_REGISTRY_ASSET_MANAGER,
            process.env.APX_REGISTRY_PRICE_MANAGER
        );

    const campaignFeeManager: Contract = (process.env.CAMPAIGN_FEE_MANAGER) ?
        await ethers.getContractAt("CampaignFeeManager", process.env.CAMPAIGN_FEE_MANAGER) :
        await helpers.deployCampaignFeeManager(
            deployer,
            process.env.CAMPAIGN_FEE_MANAGER_OWNER,
            process.env.CAMPAIGN_FEE_MANAGER_TREASURY
        );

    const revenueFeeManager: Contract = (process.env.REVENUE_FEE_MANAGER) ?
    await ethers.getContractAt("RevenueFeeManager", process.env.REVENUE_FEE_MANAGER) :
    await helpers.deployRevenueFeeManager(
        deployer,
        process.env.REVENUE_FEE_MANAGER_OWNER,
        process.env.REVENUE_FEE_MANAGER_TREASURY
    );
    
    const merkleTreePathValidator: Contract = (process.env.MERKLE_TREE_PATH_VALIDATOR) ?
        await ethers.getContractAt("MerkleTreePathValidator", process.env.MERKLE_TREE_PATH_VALIDATOR) :
        await helpers.deployMerkleTreePathValidator(deployer);

    const payoutManager: Contract = (process.env.PAYOUT_MANAGER) ?
        await ethers.getContractAt("PayoutManager", process.env.PAYOUT_MANAGER) :
        await helpers.deployPayoutManager(deployer, merkleTreePathValidator.address, revenueFeeManager.address);

    const mirroredToken: Contract = (process.env.MIRRORED_TOKEN) ?
        await ethers.getContractAt("MirroredToken", process.env.MIRRORED_TOKEN) :
        await helpers.deployMirroredToken(
            deployer,
            process.env.MIRRORED_TOKEN_NAME,
            process.env.MIRRORED_TOKEN_SYMBOL,
            process.env.MIRRORED_TOKEN_ORIGINAL
        );

    const issuerFactory: Contract = (process.env.ISSUER_FACTORY) ?
        await ethers.getContractAt("IssuerFactory", process.env.ISSUER_FACTORY) :
        await helpers.deployIssuerFactory(
            deployer,
            process.env.NAME_REGISTRY ? process.env.ISSUER_FACTORY_OLD : addressZero
        );

    const assetFactory: Contract = (process.env.ASSET_FACTORY) ?
        await ethers.getContractAt("AssetFactory", process.env.ASSET_FACTORY) :
        await helpers.deployAssetFactory(
            deployer,
            process.env.NAME_REGISTRY ? process.env.ASSET_FACTORY_OLD : addressZero
        );

    const assetTransferableFactory: Contract = (process.env.ASSET_TRANSFERABLE_FACTORY) ?
        await ethers.getContractAt("AssetTransferableFactory", process.env.ASSET_TRANSFERABLE_FACTORY) :
        await helpers.deployAssetTransferableFactory(
            deployer,
            process.env.NAME_REGISTRY ? process.env.ASSET_TRANSFERABLE_FACTORY_OLD : addressZero
        );

    const assetSimpleFactory: Contract = (process.env.ASSET_SIMPLE_FACTORY) ?
        await ethers.getContractAt("AssetSimpleFactory", process.env.ASSET_SIMPLE_FACTORY) :
        await helpers.deployAssetSimpleFactory(
            deployer,
            process.env.NAME_REGISTRY ? process.env.ASSET_SIMPLE_FACTORY_OLD : addressZero
        );

    const cfManagerFactory: Contract = (process.env.CF_MANAGER_FACTORY) ?
        await ethers.getContractAt("CfManagerSoftcapFactory", process.env.CF_MANAGER_FACTORY) :
        await helpers.deployCfManagerFactory(
            deployer,
            process.env.NAME_REGISTRY ? process.env.CF_MANAGER_FACTORY_OLD : addressZero
        );

    const cfManagerVestingFactory: Contract = (process.env.CF_MANAGER_VESTING_FACTORY) ?
        await ethers.getContractAt("CfManagerSoftcapVestingFactory", process.env.CF_MANAGER_VESTING_FACTORY) :
        await helpers.deployCfManagerVestingFactory(
            deployer,
            process.env.NAME_REGISTRY ? process.env.CF_MANAGER_VESTING_FACTORY_OLD : addressZero
        );

    const nameRegistry: Contract = (process.env.NAME_REGISTRY) ?
        await ethers.getContractAt("NameRegistry", process.env.NAME_REGISTRY) :
        await helpers.deployNameRegistry(deployer, process.env.NAME_REGISTRY_OWNER, [
            issuerFactory.address,
            assetFactory.address,
            assetTransferableFactory.address,
            assetSimpleFactory.address,
            cfManagerFactory.address,
            cfManagerVestingFactory.address
        ]);

    if (
        process.env.NAME_REGISTRY_OLD && !process.env.NAME_REGISTRY && 
        process.env.ISSUER_FACTORY_OLD && process.env.ISSUER_FACTORY_OLD != addressZero
    ) { 
        await issuerFactory.addInstancesForNewRegistry(
            process.env.ISSUER_FACTORY_OLD,
            process.env.NAME_REGISTRY_OLD,
            nameRegistry.address
        )
    }

    if (
        process.env.NAME_REGISTRY_OLD && !process.env.NAME_REGISTRY && 
        process.env.ASSET_FACTORY_OLD && process.env.ASSET_FACTORY_OLD != addressZero
    ) { 
        await assetFactory.addInstancesForNewRegistry(
            process.env.ASSET_FACTORY_OLD,
            process.env.NAME_REGISTRY_OLD,
            nameRegistry.address
        )
    }

    if (
        process.env.NAME_REGISTRY_OLD && !process.env.NAME_REGISTRY && 
        process.env.ASSET_TRANSFERABLE_FACTORY_OLD && process.env.ASSET_TRANSFERABLE_FACTORY_OLD != addressZero 
    ) { 
        await assetTransferableFactory.addInstancesForNewRegistry(
            process.env.ASSET_TRANSFERABLE_FACTORY_OLD,
            process.env.NAME_REGISTRY_OLD,
            nameRegistry.address
        )
    }
    
    if (
        process.env.NAME_REGISTRY_OLD && !process.env.NAME_REGISTRY && 
        process.env.ASSET_SIMPLE_FACTORY_OLD && process.env.ASSET_SIMPLE_FACTORY_OLD != addressZero
    ) { 
        await assetSimpleFactory.addInstancesForNewRegistry(
            process.env.ASSET_SIMPLE_FACTORY_OLD,
            process.env.NAME_REGISTRY_OLD,
            nameRegistry.address
        )
    }

    if (
        process.env.NAME_REGISTRY_OLD && !process.env.NAME_REGISTRY && 
        process.env.CF_MANAGER_FACTORY_OLD && process.env.CF_MANAGER_FACTORY_OLD != addressZero
    ) { 
        await cfManagerFactory.addInstancesForNewRegistry(
            process.env.CF_MANAGER_FACTORY_OLD,
            process.env.NAME_REGISTRY_OLD,
            nameRegistry.address
        )
    }

    if (
        process.env.NAME_REGISTRY_OLD && !process.env.NAME_REGISTRY && 
        process.env.CF_MANAGER_VESTING_FACTORY_OLD && process.env.CF_MANAGER_VESTING_FACTORY_OLD != addressZero
    ) { 
        await cfManagerVestingFactory.addInstancesForNewRegistry(
            process.env.CF_MANAGER_VESTING_FACTORY_OLD,
            process.env.NAME_REGISTRY_OLD,
            nameRegistry.address
        )
    }
    
    const walletApprovers: string[] = (process.env.WALLET_APPROVER_ADDRESSES) ? 
        process.env.WALLET_APPROVER_ADDRESSES.split(",") : [ ]; 
    const walletApproverService: Contract = (process.env.WALLET_APPROVER) ?
        await ethers.getContractAt("WalletApproverService", process.env.WALLET_APPROVER) :
        await helpers.deployWalletApproverService(
            deployer,
            process.env.WALLET_APPROVER_MASTER_OWNER,
            walletApprovers,
            process.env.FAUCET_SERVICE_REWARD_PER_APPROVE
        );

    const allowedCallers: string[] = (process.env.FAUCET_SERVICE_ALLOWED_CALLERS) ?
        process.env.FAUCET_SERVICE_ALLOWED_CALLERS.split(",") : [ ];
    const faucetService: Contract = (process.env.FAUCET_SERVICE) ?
        await ethers.getContractAt("FaucetService", process.env.FAUCET_SERVICE) :
        await helpers.deployFaucetService(
            deployer,
            process.env.FAUCET_SERVICE_MASTER_OWNER,
            allowedCallers,
            process.env.FAUCET_SERVICE_REWARD_PER_APPROVE,
            process.env.FAUCET_SERVICE_BALANCE_THRESHOLD_FOR_REWARD
        );

    const deployerService: Contract = (process.env.DEPLOYER_SERVICE) ?
        await ethers.getContractAt("DeployerService", process.env.DEPLOYER_SERVICE) :
        await helpers.deployDeployerService(deployer);

    const queryService: Contract = (process.env.QUERY_SERVICE) ?
        await ethers.getContractAt("QueryService", process.env.QUERY_SERVICE) :
        await helpers.deployQueryService(deployer);

    const investService: Contract = (process.env.INVEST_SERVICE) ?
        await ethers.getContractAt("InvestService", process.env.INVEST_SERVICE) :
        await helpers.deployInvestService(deployer);
    
    const payoutService: Contract = (process.env.PAYOUT_SERVICE) ?
        await ethers.getContractAt("PayoutService", process.env.PAYOUT_SERVICE) :
        await helpers.deployPayoutService(deployer);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });

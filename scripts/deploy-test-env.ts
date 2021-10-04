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
    console.log(`Deployer balance (accounts[0]):`, (await ethers.provider.getBalance(deployerAddress)).toString());

    const stablecoin: Contract = (process.env.STABLECOIN) ? 
        await ethers.getContractAt("USDC", process.env.STABLECOIN) :
        await helpers.deployStablecoin(deployer, "10000000000");

    const apxRegistry: Contract = (process.env.APX_REGISTRY) ?
        await ethers.getContractAt("ApxAssetsRegistry", process.env.APX_REGISTRY) :
        await helpers.deployApxRegistry(
            deployer,
            process.env.APX_REGISTRY_MASTER_OWNER,
            process.env.APX_REGISTRY_ASSET_MANAGER,
            process.env.APX_REGISTRY_PRICE_MANAGER
        );

    const mirroredToken: Contract = (process.env.MIRRORED_TOKEN) ?
        await ethers.getContractAt("MirroredToken", process.env.MIRRORED_TOKEN) :
        await helpers.deployMirroredToken(
            deployer,
            process.env.MIRRORED_TOKEN_NAME,
            process.env.MIRRORED_TOKEN_SYMBOL,
            process.env.MIRRORED_TOKEN_ORIGINAL,
            process.env.MIRRORED_TOKEN_CHILD_CHAIN_MANAGER
        );

    const issuerFactory: Contract = (process.env.ISSUER_FACTORY) ?
        await ethers.getContractAt("IssuerFactory", process.env.ISSUER_FACTORY) :
        await helpers.deployIssuerFactory(deployer);

    const assetFactory: Contract = (process.env.ASSET_FACTORY) ?
        await ethers.getContractAt("AssetFactory", process.env.ASSET_FACTORY) :
        await helpers.deployAssetFactory(deployer);

    const assetTransferableFactory: Contract = (process.env.ASSET_TRANSFERABLE_FACTORY) ?
        await ethers.getContractAt("AssetTransferableFactory", process.env.ASSET_TRANSFERABLE_FACTORY) :
        await helpers.deployAssetTransferableFactory(deployer);

    const assetSimpleFactory: Contract = (process.env.ASSET_SIMPLE_FACTORY) ?
        await ethers.getContractAt("AssetSimpleFactory", process.env.ASSET_SIMPLE_FACTORY) :
        await helpers.deployAssetSimpleFactory(deployer);

    const cfManagerFactory: Contract = (process.env.CF_MANAGER_FACTORY) ?
        await ethers.getContractAt("CfManagerSoftcapFactory", process.env.CF_MANAGER_FACTORY) :
        await helpers.deployCfManagerFactory(deployer);

    const cfManagerVestingFactory: Contract = (process.env.CF_MANAGER_VESTING_FACTORY) ?
        await ethers.getContractAt("CfManagerSoftcapVestingFactory", process.env.CF_MANAGER_VESTING_FACTORY) :
        await helpers.deployCfManagerVestingFactory(deployer);

    const snapshotDistributorFactory: Contract = (process.env.SNAPSHOT_DISTRIBUTOR_FACTORY) ?
        await ethers.getContractAt("SnapshotDistributorFactory", process.env.SNAPSHOT_DISTRIBUTOR_FACTORY) :
        await helpers.deploySnapshotDistributorFactory(deployer);

    const nameRegistry: Contract = (process.env.NAME_REGISTRY) ?
        await ethers.getContractAt("NameRegistry", process.env.NAME_REGISTRY) :
        await helpers.deployNameRegistry(deployer, process.env.NAME_REGISTRY_OWNER, [
            issuerFactory.address,
            assetFactory.address,
            assetTransferableFactory.address,
            cfManagerFactory.address,
            snapshotDistributorFactory.address
        ]);
    
    const walletApproverService: Contract = (process.env.WALLET_APPROVER) ?
        await ethers.getContractAt("WalletApproverService", process.env.WALLET_APPROVER) :
        await helpers.deployWalletApproverService(deployer, process.env.WALLET_APPROVER_MASTER_OWNER, "0.001");

    const deployerService: Contract = (process.env.DEPLOYER) ?
        await ethers.getContractAt("DeployerService", process.env.DEPLOYER) :
        await helpers.deployDeployerService(deployer);

    const queryService: Contract = (process.env.QUERY_SERVICE) ?
        await ethers.getContractAt("QueryService", process.env.QUERY_SERVICE) :
        await helpers.deployQueryService(deployer);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });

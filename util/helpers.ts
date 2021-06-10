import { ethers } from "hardhat";
import { Contract, ContractFactory, Signer } from "ethers";

const factories: Map<String, ContractFactory> = new Map();

export async function deployStablecoin(deployer: Signer, ticker: string, supply: string): Promise<Contract> {
    const supplyWei = ethers.utils.parseEther(supply);
    const USDC = await ethers.getContractFactory(ticker, deployer);
    const stablecoin = await USDC.deploy(supplyWei);
    console.log(`Stablecoin deployed at: ${stablecoin.address}`);
    factories[stablecoin.address] = USDC.interface;
    return stablecoin;
  }

export async function deployGlobalRegistry(deployer: Signer): Promise<Contract> {
    const GlobalRegistry = await ethers.getContractFactory("GlobalRegistry", deployer);
    
    const IssuerFactory = await ethers.getContractFactory("IssuerFactory", deployer);
    const AssetFactory = await ethers.getContractFactory("AssetFactory", deployer);
    const CfManagerFactory = await ethers.getContractFactory("CfManagerFactory", deployer);
    const PayoutManagerFactory = await ethers.getContractFactory("PayoutManagerFactory", deployer);

    const issuerFactory = await IssuerFactory.deploy();
    factories[issuerFactory.address] = IssuerFactory;
    console.log(`IssuerFactory deployed at: ${issuerFactory.address}`);

    const assetFactory = await AssetFactory.deploy();
    factories[assetFactory.address] = AssetFactory;
    console.log(`AssetFactory deployed at: ${assetFactory.address}`);

    const cfManagerFactory = await CfManagerFactory.deploy();
    factories[cfManagerFactory.address] = CfManagerFactory;
    console.log(`CfManagerFactory deployed at: ${cfManagerFactory.address}`);

    const payoutManagerFactory = await PayoutManagerFactory.deploy();
    factories[payoutManagerFactory.address] = PayoutManagerFactory;
    console.log(`PayoutManagerFactory deployed at: ${payoutManagerFactory.address}`);

    const registry = await GlobalRegistry.deploy(
      issuerFactory.address,
      assetFactory.address,
      cfManagerFactory.address,
      payoutManagerFactory.address
    );
    console.log(`Global Registry deployed at: ${registry.address}`);
    return registry;
  }

export async function createIssuer(
    from: Signer,
    registry: Contract,
    stablecoinAddress: String
  ): Promise<Contract> {
    const fromAddress = await from.getAddress();
    const issuerFactory = (await ethers.getContractAt("IssuerFactory", await registry.issuerFactory())).connect(from);
    const issuerTx = await issuerFactory.create(
      fromAddress,
      stablecoinAddress,
      registry.address
    );
    const receipt = await ethers.provider.getTransactionReceipt(issuerTx.hash);
    for (const log of receipt.logs) {
      const parsedLog = issuerFactory.interface.parseLog(log);
      if (parsedLog.name == "IssuerCreated") {
        return (await ethers.getContractAt("Issuer", parsedLog.args[0])).connect(from);
      }
    }
    throw new Error("Issuer creation transaction failed.");
  }

export async function createCfManager(
    from: Signer,
    issuer: Contract,
    categoryId: Number,
    totalShares: Number,
    name: String,
    symbol: String,
    minInvestment: Number,
    maxInvestment: Number,
    endsAt: Number
  ): Promise<[Contract, Contract]> {
    const issuerWithSigner = issuer.connect(from);
    const cfManagerTx = await issuerWithSigner.createCrowdfundingCampaign(
      categoryId,
      ethers.utils.parseEther(totalShares.toString()),
      name,
      symbol,
      ethers.utils.parseEther(minInvestment.toString()),
      ethers.utils.parseEther(maxInvestment.toString()),
      endsAt
    );
    const receipt = await ethers.provider.getTransactionReceipt(cfManagerTx.hash);

    let cfManagerAddress;
    let assetAddress;
    for (const log of receipt.logs) {
      const contractFactory = factories[log.address];
      if (contractFactory) {
        const parsedLog = contractFactory.interface.parseLog(log);
        switch (parsedLog.name) {
          case "AssetCreated": { assetAddress = parsedLog.args[0]; break; }
          case "CfManagerCreated": { cfManagerAddress = parsedLog.args[0]; break; }
        }
      }
    }

    console.log("CfManager deployed at: ", cfManagerAddress);
    console.log("Asset deplyed at: ", assetAddress);
    const cfManager = await ethers.getContractAt("CfManager", cfManagerAddress);
    const asset = await ethers.getContractAt("Asset", assetAddress);
    return [cfManager, asset];
  }
  
export async function createPayoutManager(
    from: Signer,
    registry: Contract,
    assetAddress: String
  ): Promise<Contract> {
    const fromAddress = await from.getAddress();
    const payoutManagerFactory = (await ethers.getContractAt("PayoutManagerFactory", await registry.payoutManagerFactory())).connect(from);
    const payoutManagerTx = await payoutManagerFactory.create(fromAddress, assetAddress);
    const receipt = await ethers.provider.getTransactionReceipt(payoutManagerTx.hash);
    for (const log of receipt.logs) {
      const parsedLog = payoutManagerFactory.interface.parseLog(log);
      if (parsedLog.name == "PayoutManagerCreated") {
        return ethers.getContractAt("PayoutManager", parsedLog.args[0]);
      }
    }
    throw new Error("PayoutManager transaction failed.");
  }

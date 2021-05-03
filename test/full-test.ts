import { ethers } from "hardhat";
import { Contract, ContractFactory, Signer } from "ethers";
import { expect } from "chai";
import { currentTimeWithDaysOffset } from "./util";

describe("Full test", function () {
  
  let deployer: Signer;
  let issuerOwner: Signer;
  let cfManagerOwner: Signer;
  let investor: Signer;

  let Issuer: ContractFactory;
  let issuer: Contract;

  let stablecoin: Contract;

  let factories: Map<String, ContractFactory> = new Map();

  beforeEach(async function () {
    const accounts: Signer[] = await ethers.getSigners();
    deployer        = accounts[0];
    issuerOwner     = accounts[1];
    cfManagerOwner  = accounts[2];
    investor        = accounts[3];
    await initStablecoin();
  });

  it(
    `should successfully complete the flow:\n
          1)create Issuer\n
          2)create crowdfunding campaign\n
          3)successfully fund the project
    `,
    async function () {
      //// Create factories
      const CfManagerFactory = await ethers.getContractFactory("CfManagerFactory", deployer);
      const cfManagerFactory = await CfManagerFactory.deploy();
      factories[cfManagerFactory.address] = CfManagerFactory.interface;

      const AssetFactory = await ethers.getContractFactory("AssetFactory", deployer);
      const assetFactory = await AssetFactory.deploy();
      factories[assetFactory.address] = AssetFactory.interface;

      //// Deploy issuer
      Issuer = await ethers.getContractFactory("Issuer", issuerOwner);
      issuer = await Issuer.deploy(
        stablecoin.address,
        assetFactory.address,
        cfManagerFactory.address
      );
      factories[issuer.address] = Issuer.interface;
      await issuer.approveWallet(await cfManagerOwner.getAddress());

      //// Deploy crowdfunding campaign (creates campaign + asset)
      const [cfManager, asset] = await createCfManager(
        cfManagerOwner,
        0,
        10000000,
        "WESPA Spaces",
        "aWSPA",
        100,
        10000000,
        currentTimeWithDaysOffset(1)
      )

      //// Activate new investor and fund his wallet with stablecoin
      const investorAddress = await investor.getAddress();
      await issuer.approveWallet(investorAddress);
      await stablecoin.transfer(investorAddress, ethers.utils.parseEther(String(10000000)));

      //// Fully fund the campaign and check if Asset is in state TOKENIZED
      const investorUSDC = stablecoin.connect(investor);
      await investorUSDC.approve(cfManager.address, ethers.utils.parseEther(String(10000000)));
      const investorCfManager = cfManager.connect(investor);
      await investorCfManager.invest(ethers.utils.parseEther(String(10000000))); 
      const assetState = await asset.state();
      expect(assetState).to.be.equal(1);
    }
  );

  async function initStablecoin() {
    const supply = ethers.utils.parseEther("1000000000000");
    const USDC = await ethers.getContractFactory("USDC", deployer);
    stablecoin = await USDC.deploy(supply);
    factories[stablecoin.address] = USDC.interface;
  }

  async function createCfManager(
    from: Signer,
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
        const parsedLog = contractFactory.parseLog(log);
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

});

import { ethers } from "hardhat";
import { Contract, ContractFactory, Signer } from "ethers";
import { expect } from "chai";
import { currentTimeWithDaysOffset } from "./util";

describe("Full test", function () {
  
  let deployer: Signer;
  let issuerOwner: Signer;
  let cfManagerOwner: Signer;
  let bob: Signer;
  let alice: Signer;
  let jane: Signer;
  let frank: Signer;

  let issuer: Contract;
  let stablecoin: Contract;
  let payoutManagerFactory: Contract;
  let issuerFactory: Contract;

  let factories: Map<String, ContractFactory> = new Map();

  beforeEach(async function () {
    const accounts: Signer[] = await ethers.getSigners();
    deployer        = accounts[0];
    issuerOwner     = accounts[1];
    cfManagerOwner  = accounts[2];
    bob             = accounts[3];
    alice           = accounts[4];
    jane            = accounts[5];
    frank           = accounts[6];
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

      const PayoutManagerFactory = await ethers.getContractFactory("PayoutManagerFactory", deployer);
      payoutManagerFactory = await PayoutManagerFactory.deploy();

      const IssuerFactory = await ethers.getContractFactory("IssuerFactory", deployer);
      issuerFactory = await IssuerFactory.deploy();

      //// Deploy issuer
      issuer = await createIssuer(
        issuerOwner,
        stablecoin.address,
        assetFactory.address,
        cfManagerFactory.address
      );
      await issuer.approveWallet(await cfManagerOwner.getAddress());

      //// Deploy crowdfunding campaign (creates campaign + asset). Activate asset.
      const categoryId = 0;
      const investmentCap = 10000000; 
      const minInvestment = 100;
      const maxInvestment = 10000000;
      const [cfManager, asset] = await createCfManager(
        cfManagerOwner,
        categoryId,
        investmentCap,
        "WESPA Spaces",
        "aWSPA",
        minInvestment,
        maxInvestment,
        currentTimeWithDaysOffset(1)
      );
      await issuer.approveWallet(asset.address);

      //// Activate new investor and fund his wallet with stablecoin
      const cfManagerOwnerAddress = await cfManagerOwner.getAddress();
      const firstRevenuePayout = 10000000;
      const secondRevenuePayout = 10000000;
      await issuer.approveWallet(cfManagerOwnerAddress);
      await stablecoin.transfer(cfManagerOwnerAddress, ethers.utils.parseEther(String(firstRevenuePayout + secondRevenuePayout)));

      //// Activate new investor and fund his wallet with stablecoin
      const aliceAddress = await alice.getAddress();
      const aliceInvestment = 3000000;
      await issuer.approveWallet(aliceAddress);
      await stablecoin.transfer(aliceAddress, ethers.utils.parseEther(String(aliceInvestment)));

      //// Activate new investor and fund his wallet with stablecoin
      const janeAddress = await jane.getAddress();
      const janeInvestment = 7000000;
      await issuer.approveWallet(janeAddress);
      await stablecoin.transfer(janeAddress, ethers.utils.parseEther(String(janeInvestment)));

      //// Activate new investor and fund his wallet with stablecoin
      const frankAddress = await frank.getAddress();
      await issuer.approveWallet(frankAddress);

      //// Alice invests 30%
      const aliceUSDC = stablecoin.connect(alice);
      await aliceUSDC.approve(cfManager.address, ethers.utils.parseEther(String(aliceInvestment)));
      const aliceCfManager = cfManager.connect(alice);
      await aliceCfManager.invest(ethers.utils.parseEther(String(aliceInvestment)));

      //// Jane invests 70%
      const janeUSDC = stablecoin.connect(jane);
      await janeUSDC.approve(cfManager.address, ethers.utils.parseEther(String(janeInvestment)));
      const janeCfManager = cfManager.connect(jane);
      await janeCfManager.invest(ethers.utils.parseEther(String(janeInvestment)));

      //// Check project fully funded
      const assetState = await asset.state();
      expect(assetState).to.be.equal(1);

      //// Set and fetch asset info
      const assetInfoHashIPFS = "QmYA2fn8cMbVWo4v95RwcwJVyQsNtnEwHerfWR8UNtEwoE";
      await asset.connect(cfManagerOwner).setInfo(assetInfoHashIPFS);
      expect(await asset.info()).to.be.equal(assetInfoHashIPFS);

      //// Create Payment Manager and make the first payment
      const payoutManager = await createPayoutManager(cfManagerOwner, asset.address);
      const cfManagerOwnerUSDC = stablecoin.connect(cfManagerOwner);
      const firstRevenuePayoutWei = ethers.utils.parseEther(String(firstRevenuePayout));
      await cfManagerOwnerUSDC.approve(payoutManager.address, firstRevenuePayoutWei);
      await payoutManager.connect(cfManagerOwner).createPayout("Q3/2020 Ape-le shareholders payout timeee", firstRevenuePayoutWei);

      //// Alice and Jane claim their revenue shares. Check the numbers.
      const firstPayoutSnapshotID = 1;
      const expectedAliceFirstPayoutCut = ethers.utils.parseEther(String((aliceInvestment * firstRevenuePayout) / investmentCap));
      const expectedJaneFirstPayoutCut = ethers.utils.parseEther(String((janeInvestment * firstRevenuePayout) / investmentCap));
      expect(await stablecoin.balanceOf(aliceAddress)).to.be.equal(0);
      expect(await stablecoin.balanceOf(janeAddress)).to.be.equal(0);
      await payoutManager.release(aliceAddress, firstPayoutSnapshotID);
      await payoutManager.release(janeAddress, firstPayoutSnapshotID);
      expect(await stablecoin.balanceOf(aliceAddress)).to.be.equal(expectedAliceFirstPayoutCut);
      expect(await stablecoin.balanceOf(janeAddress)).to.be.equal(expectedJaneFirstPayoutCut);

      //// Jane transfers all of her shares to Frank (ownership structure is being changed).
      const janeShares = await asset.balanceOf(janeAddress);
      await asset.connect(jane).transfer(frankAddress, janeShares);

      //// Make the second payment for the project shareholders. Alice and Frank claim their revenue shares. Check the numbers.
      const secondRevenuePayoutWei = ethers.utils.parseEther(String(secondRevenuePayout));
      await cfManagerOwnerUSDC.approve(payoutManager.address, secondRevenuePayoutWei);
      await payoutManager.connect(cfManagerOwner).createPayout("Q4/2020 Ape-le shareholders payout timeee", secondRevenuePayoutWei);
      const secondPayoutSnapshotID = 2;
      const expectedAliceSecondPayoutCut = ethers.utils.parseEther(String((aliceInvestment * secondRevenuePayout) / investmentCap));
      const expectedFankSecondPayoutCut = ethers.utils.parseEther(String((janeInvestment * secondRevenuePayout) / investmentCap));
      await payoutManager.release(aliceAddress, secondPayoutSnapshotID);
      await payoutManager.release(frankAddress, secondPayoutSnapshotID);
      expect(await stablecoin.balanceOf(aliceAddress)).to.be.equal(expectedAliceFirstPayoutCut.add(expectedAliceSecondPayoutCut));
      expect(await stablecoin.balanceOf(frankAddress)).to.be.equal(expectedFankSecondPayoutCut);
    }
  );

  async function initStablecoin() {
    const supply = ethers.utils.parseEther("1000000000000");
    const USDC = await ethers.getContractFactory("USDC", deployer);
    stablecoin = await USDC.deploy(supply);
    factories[stablecoin.address] = USDC.interface;
  }

  async function createIssuer(
    from: Signer,
    stablecoinAddress: String,
    assetFactoryAddress: String,
    cfManagerFactoryAddress: String
  ): Promise<Contract> {
    const fromAddress = await from.getAddress();
    const issuerFactoryWithSigner = issuerFactory.connect(from);
    const issuerTx = await issuerFactoryWithSigner.create(
      fromAddress,
      stablecoinAddress,
      assetFactoryAddress,
      cfManagerFactoryAddress
    );
    const receipt = await ethers.provider.getTransactionReceipt(issuerTx.hash);
    for (const log of receipt.logs) {
      const parsedLog = issuerFactory.interface.parseLog(log);
      if (parsedLog.name == "IssuerCreated") {
        return (await ethers.getContractAt("Issuer", parsedLog.args[0])).connect(from);
      }
    }
    throw new Error("Issuer creation transaction failed.")
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
  
  async function createPayoutManager(
    from: Signer,
    assetAddress: String
  ): Promise<Contract> {
    const fromAddress = await from.getAddress();
    const payoutManagerFactoryWithSigner = payoutManagerFactory.connect(from);
    const payoutManagerTx = await payoutManagerFactoryWithSigner.create(fromAddress, assetAddress);
    const receipt = await ethers.provider.getTransactionReceipt(payoutManagerTx.hash);
    for (const log of receipt.logs) {
      const parsedLog = payoutManagerFactory.interface.parseLog(log);
      if (parsedLog.name == "PayoutManagerCreated") {
        return ethers.getContractAt("PayoutManager", parsedLog.args[0]);
      }
    }
    throw new Error("PayoutManager transaction failed.")
  }

});

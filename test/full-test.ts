import { ethers } from "hardhat";
import { Contract, ContractFactory, Signer } from "ethers";
import { expect } from "chai";
import { currentTimeWithDaysOffset } from "./util";

describe("Full test", function () {
  
  let deployer: Signer;
  let issuerOwner: Signer;
  let cfManagerOwner: Signer;
  let alice: Signer;
  let jane: Signer;
  let frank: Signer;

  let registry: Contract;
  let issuer: Contract;
  let stablecoin: Contract;

  let factories: Map<String, ContractFactory> = new Map();

  beforeEach(async function () {
    const accounts: Signer[] = await ethers.getSigners();
    deployer        = accounts[0];
    issuerOwner     = accounts[1];
    cfManagerOwner  = accounts[2];
    alice           = accounts[3];
    jane            = accounts[4];
    frank           = accounts[5];
    await deployStablecoin();
    await deployGlobalRegistry();
  });

  it(
    `should successfully complete the flow:\n
          1)create Issuer\n
          2)create crowdfunding campaign\n
          3)successfully fund the project
    `,
    async function () {

      //// Deploy issuer
      issuer = await createIssuer(
        issuerOwner,
        stablecoin.address
      );
      console.log(`Issuer deployed at: ${issuer.address}`);
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

      //// Set and fetch auditing procedure
      const auditingProcedureIpfsHash = "QmYA2fn8cMbVWo4v95RwcwJVyQsNtnEwHerfWR8UNtEwoE";
      const assetId = await asset.categoryId();
      await registry.setAuditingProcedure(assetId, auditingProcedureIpfsHash);
      expect(await registry.auditingProcedures(assetId)).to.be.equal(auditingProcedureIpfsHash);

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

  async function deployStablecoin() {
    const supply = ethers.utils.parseEther("1000000000000");
    const USDC = await ethers.getContractFactory("USDC", deployer);
    stablecoin = await USDC.deploy(supply);
    console.log(`Stablecoin deployed at: ${stablecoin.address}`);
    factories[stablecoin.address] = USDC.interface;
  }

  async function deployGlobalRegistry() {
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

    registry = await GlobalRegistry.deploy(
      issuerFactory.address,
      assetFactory.address,
      cfManagerFactory.address,
      payoutManagerFactory.address
    );
    console.log(`Global Registry deployed at: ${registry.address}`);
  }

  async function createIssuer(
    from: Signer,
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
  
  async function createPayoutManager(
    from: Signer,
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

});

import { ethers } from "hardhat";
import { Contract, ContractFactory, Signer } from "ethers";
import { expect } from "chai";
import { currentTimeWithDaysOffset } from "../util/helpers";
import * as helpers from "../util/helpers";
import { AssetState } from "../util/types";

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

  beforeEach(async function () {
    const accounts: Signer[] = await ethers.getSigners();
    deployer        = accounts[0];
    issuerOwner     = accounts[1];
    cfManagerOwner  = accounts[1];
    alice           = accounts[3];
    jane            = accounts[4];
    frank           = accounts[5];

    stablecoin = await helpers.deployStablecoin(deployer, "1000000000000");
    registry = await helpers.deployGlobalRegistry(deployer);
  });

  it(
    `should successfully complete the flow:\n
          1)create Issuer\n
          2)create crowdfunding campaign\n
          3)successfully fund the project
    `,
    async function () {

      //// Deploy issuer
      issuer = await helpers.createIssuer(
        issuerOwner,
        registry,
        stablecoin.address,
        "info-hash"
      );
      console.log(`Issuer deployed at: ${issuer.address}`);
      await issuer.approveWallet(await cfManagerOwner.getAddress());

      //// Deploy crowdfunding campaign (creates campaign + asset). Activate asset.
      const categoryId = 0;
      const investmentCap = 10000000; 
      const minInvestment = 100;
      const maxInvestment = 10000000;
      const [cfManager, asset] = await helpers.createCfManager(
        cfManagerOwner,
        issuer,
        categoryId,
        investmentCap,
        "WESPA Spaces",
        "aWSPA",
        minInvestment,
        maxInvestment,
        currentTimeWithDaysOffset(1)
      );
      await issuer.approveWallet(asset.address);

      //// Activate crowdfunding manager wallet
      const cfManagerOwnerAddress = await cfManagerOwner.getAddress();
      await issuer.approveWallet(cfManagerOwnerAddress);

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

      //// Alice invests 30%, cancels, and then invests again
      const aliceUSDC = stablecoin.connect(alice);
      const aliceInvestmentWei = ethers.utils.parseEther(String(aliceInvestment));
      await aliceUSDC.approve(cfManager.address, aliceInvestmentWei);
      const aliceCfManager = cfManager.connect(alice);
      await aliceCfManager.invest(aliceInvestmentWei);

      //// Jane invests 70%, cancels, and then invests again
      const janeUSDC = stablecoin.connect(jane);
      const janeInvestmentWei = ethers.utils.parseEther(String(janeInvestment));
      await janeUSDC.approve(cfManager.address, janeInvestmentWei);
      const janeCfManager = cfManager.connect(jane);
      await janeCfManager.invest(janeInvestmentWei);
      expect(await stablecoin.balanceOf(janeAddress)).to.be.equal(0);
      await janeCfManager.cancelInvestment();
      expect(await stablecoin.balanceOf(janeAddress)).to.be.equal(janeInvestmentWei);
      await janeUSDC.approve(cfManager.address, janeInvestmentWei);
      await janeCfManager.invest(janeInvestmentWei);

      //// Campaign Manager finalizes the crowdfunding process
      await cfManager.connect(cfManagerOwner).finalize();
      expect(await asset.state()).to.be.equal(AssetState.TOKENIZED);
      expect(await asset.creator()).to.be.equal(cfManagerOwnerAddress);
      expect(await stablecoin.balanceOf(cfManagerOwnerAddress)).to.be.equal(ethers.utils.parseEther(String(investmentCap)));

      //// Set and fetch issuer info
      const issuerInfoHashIPFS = "QmYA2fn8cMbVWo4v95RwcwJVyQsNtnEwHerfWR8UNtEwoE";
      await issuer.connect(issuerOwner).setInfo(issuerInfoHashIPFS);
      expect(await issuer.info()).to.be.equal(issuerInfoHashIPFS);

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
      const firstRevenuePayout = 10000000;
      const secondRevenuePayout = 10000000;
      await stablecoin.transfer(cfManagerOwnerAddress, ethers.utils.parseEther(String(firstRevenuePayout + secondRevenuePayout)));
      const payoutManager = await helpers.createPayoutManager(cfManagerOwner, registry, asset.address);
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


      //// Fetch all the instances from contracts - check the data
      const issuerFactoryInstances = await (await ethers.getContractAt("IssuerFactory", await registry.issuerFactory())).getInstances();
      expect(issuerFactoryInstances).to.have.lengthOf(1);
      expect(issuer.address).to.be.oneOf(issuerFactoryInstances);

      const assetFactoryInstances = await (await ethers.getContractAt("AssetFactory", await registry.assetFactory())).getInstances();
      expect(assetFactoryInstances).to.have.lengthOf(1);
      expect(asset.address).to.be.oneOf(assetFactoryInstances);

      const cfManagerFactoryInstances = await (await ethers.getContractAt("CfManagerFactory", await registry.cfManagerFactory())).getInstances();
      expect(cfManagerFactoryInstances).to.have.lengthOf(1);
      expect(cfManager.address).to.be.oneOf(cfManagerFactoryInstances);

      const payoutManagerFactoryInstances = await (await ethers.getContractAt("PayoutManagerFactory", await registry.payoutManagerFactory())).getInstances();
      expect(payoutManagerFactoryInstances).to.have.lengthOf(1);
      expect(payoutManager.address).to.be.oneOf(payoutManagerFactoryInstances);

      const issuerAssetInstances = await issuer.getAssets();
      expect(issuerAssetInstances).to.have.lengthOf(1);
      expect(asset.address).to.be.oneOf(issuerAssetInstances);

      const issuerCfManagerInstances = await issuer.getCfManagers();
      expect(issuerCfManagerInstances).to.have.lengthOf(1);
      expect(cfManager.address).to.be.oneOf(issuerCfManagerInstances);
    }
  );

});

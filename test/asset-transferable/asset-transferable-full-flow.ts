// @ts-ignore
import {ethers} from "hardhat";
import {expect} from "chai";
import * as helpers from "../../util/helpers";
import {TestData} from "../TestData";
import { BigNumber } from "ethers";

describe("Asset transferable - full test", function () {

  const testData = new TestData()

  beforeEach(async function () {
    await testData.deploy()
  });

  it(
    `should successfully complete the flow:\n
          1)create Issuer + AssetTransferable + Campaign using deployer service
          2)successfully fund the project with two different investors
          3)update asset price
          4)liquidate asset with the correct price: max(crowdfunding campaign price, market price)
          5)investors claim liquidation funds. asset owner ownes 100% of the supply
    `,
    async function () {
      const ASSET_TYPE = "AssetTransferable";
      const CAMPAIGN_TYPE = "CfManagerSoftcap";
      await testData.deployIssuerAssetTransferableCampaign()

      //// Alice buys $100k USDC and goes through kyc process (wallet approved)
      const aliceAddress = await testData.alice.getAddress();
      const aliceInvestment = 100000;
      const aliceInvestmentWei = ethers.utils.parseEther(aliceInvestment.toString());
      await testData.stablecoin.transfer(aliceAddress, aliceInvestmentWei);
      await testData.walletApproverService.connect(testData.walletApprover)
          .approveWallet(testData.issuer.address, aliceAddress);

      //// Alice invests $100k USDC in the project
      await helpers.investForBeneficiary(
          testData.alice,
          testData.alice,
          testData.cfManager,
          testData.stablecoin,
          aliceInvestment
      );

      //// Jane buys $100k USDC and goes through kyc process (wallet approved)
      const janeAddress = await testData.jane.getAddress();
      const janeInvestment = 100000;
      const janeInvestmentWei: BigNumber = ethers.utils.parseEther(janeInvestment.toString());
      await testData.stablecoin.transfer(janeAddress, janeInvestmentWei);
      await testData.walletApproverService.connect(testData.walletApprover)
          .approveWallet(testData.issuer.address, janeAddress);
    
      //// Jane invests $100k USDC in the project and then cancels her investment and then invests again
      await helpers.invest(testData.jane, testData.cfManager, testData.stablecoin, janeInvestment);
      await helpers.cancelInvest(testData.jane, testData.cfManager);
      await helpers.invest(testData.jane, testData.cfManager, testData.stablecoin, janeInvestment);

      // Asset owner finalizes the campaign as the soft cap has been reached.
      await testData.cfManager.connect(testData.issuerOwner).finalize();
      
      // Alice has to claim tokens after the campaign has been closed successfully
      await testData.cfManager.connect(testData.alice).claim(aliceAddress);
      // Jane has to claim tokens after the campaign has been closed successfully
      await testData.cfManager.connect(testData.jane).claim(janeAddress);

      //// Owner creates snapshot distributor, updates info once
      const snapshotDistributorMappedName = "snapshot-distributor";
      const snapshotDistributorInfoHash = "snapshot-distributor-info-hash";
      const updatedSnapshotDistributorInfoHash = "updated-snapshot-distributor-info-hash";
      const snapshotDistributor = await helpers.createSnapshotDistributor(
          await testData.issuerOwner.getAddress(),
          snapshotDistributorMappedName,
          testData.asset,
          snapshotDistributorInfoHash,
          testData.snapshotDistributorFactory,
          testData.nameRegistry
      );
      await helpers.setInfo(testData.issuerOwner, snapshotDistributor, updatedSnapshotDistributorInfoHash);

      //// Distribute $100k revenue to the token holders using the snapshot distributor from the step before
      const payoutDescription = "WindFarm Mexico Q3/2021 revenue";
      const revenueAmount = 300000;
      const revenueAmountWei: BigNumber = ethers.utils.parseEther(revenueAmount.toString());
      const issuerAddress = await testData.issuerOwner.getAddress();
      await testData.stablecoin.transfer(issuerAddress, revenueAmountWei);
      const balanceBeforePayout: BigNumber = await testData.stablecoin.balanceOf(issuerAddress);
      expect(balanceBeforePayout).to.be.equal(revenueAmountWei.add(janeInvestmentWei.mul(2)));
      await helpers.createPayout(testData.issuerOwner, snapshotDistributor, testData.stablecoin, revenueAmount, payoutDescription);
      const afterSharePayout = await testData.stablecoin.balanceOf(issuerAddress);
      expect(afterSharePayout).to.be.equal(balanceBeforePayout.sub(revenueAmountWei));

      //// Alice claims her revenue share by calling previously created SnapshotDistributor contract and providing the payoutId param (0 in this case)
      //// SnapshotDistributor address has to be known upfront (can be found for one asset by scanning SnapshotDistributorCreated event for asset address)
      const snapshotId = 1;
      const aliceBalanceBeforePayout = await testData.stablecoin.balanceOf(aliceAddress);
      expect(aliceBalanceBeforePayout).to.be.equal(0);
      const aliceRevenueShareWei = ethers.utils.parseEther("100000");    // (1/3) of the total revenue payed out
      await helpers.claimRevenue(testData.alice, snapshotDistributor, snapshotId);
      const aliceBalanceAfterPayout = await testData.stablecoin.balanceOf(aliceAddress);
      expect(aliceBalanceAfterPayout).to.be.equal(aliceRevenueShareWei); // alice claims (1/3) of total revenue

      //// Jane claims her revenue share by calling previously created SnapshotDistributor contract and providing the snapshotId param (0 in this case)
      //// SnapshotDistributors address has to be known upfront (can be found for one asset by scanning SnapshotDistributorCreated event for asset address)
      const janeBalanceBeforePayout = await testData.stablecoin.balanceOf(janeAddress);
      expect(janeBalanceBeforePayout).to.be.equal(0);
      const janeRevenueShareWei = ethers.utils.parseEther("100000");    // (1/3) of the total revenue payed out
      await helpers.claimRevenue(testData.jane, snapshotDistributor, snapshotId);
      const janeBalanceAfterPayout = await testData.stablecoin.balanceOf(janeAddress);
      expect(janeBalanceAfterPayout).to.be.equal(janeRevenueShareWei); // jane claims (1/3) of total revenue

      //// Asset is registered on the APX Registry and the market price is updated
      await helpers.registerAsset(
          testData.assetManager, testData.apxRegistry, testData.asset.address, testData.asset.address
      );
      // update market price for asset
      // price: $0.70, expiry: 60 seconds
      await helpers.updatePrice(testData.priceManager, testData.apxRegistry, testData.asset, 11000, 60);
      console.log("price updated");

      //// Asset owner liquidates asset
      // Asset was crowdfunded at $1/token and is now trading at $1.10/token so the total supply must be liquidated
      // at the max($1, $1.10), therefore must be liquidated at the price of $1.10.
      // Since the asset supply is 300k tokens, liqudiation funds = 300k tokens * $1.10 = $330k
      // Project owner already holds $200k at his wallet after finalizing the campaign, so we transfer another $20k
      // to his wallet and call liquidate() function. Liquidate function doesn't require full $330k payment since the
      // caller holds (1/3) of the token and is entitled to $110k claim. This is deducted in the liquidate() function so
      // caller only has to approve the liquidation funds for the rest of the holders.
      // Jane and Alice hold (1/3) of the total supply each, so they can claim $110k each.
      const liquidationAmount = 220000;
      await testData.stablecoin.transfer(issuerAddress, ethers.utils.parseEther("20000"));
      const liquidatorBalanceBeforeLiquidation = await testData.stablecoin.balanceOf(issuerAddress);
      expect (liquidatorBalanceBeforeLiquidation).to.be.equal(ethers.utils.parseEther(liquidationAmount.toString()));
      await helpers.liquidate(testData.issuerOwner, testData.asset, testData.stablecoin, liquidationAmount);
      const liquidatorBalanceAfterLiquidation = await testData.stablecoin.balanceOf(issuerAddress);
      expect (liquidatorBalanceAfterLiquidation).to.be.equal(0);
      const assetTotalSupply = await testData.asset.totalSupply();
      expect(await (testData.asset.balanceOf(issuerAddress))).to.be.equal(assetTotalSupply);

      //// Alice claims liquidation share
      const aliceLiquidationShare = 110000;
      const aliceLiquidationShareWei = ethers.utils.parseEther(aliceLiquidationShare.toString());
      await helpers.claimLiquidationShare(testData.alice, testData.asset);
      const aliceBalanceAfterLiquidationClaim = await testData.stablecoin.balanceOf(aliceAddress);
      expect(aliceBalanceAfterLiquidationClaim).to.be.equal(aliceRevenueShareWei.add(aliceLiquidationShareWei));
      expect(await testData.asset.balanceOf(aliceAddress)).to.be.equal(0);

      //// Jane claims liquidation share
      const janeLiquidationShare = 110000;
      const janeLiquidationShareWei = ethers.utils.parseEther(janeLiquidationShare.toString());
      await helpers.claimLiquidationShare(testData.jane, testData.asset);
      const janeBalanceAfterLiquidationClaim = await testData.stablecoin.balanceOf(janeAddress);
      expect(janeBalanceAfterLiquidationClaim).to.be.equal(janeRevenueShareWei.add(janeLiquidationShareWei));
      expect(await testData.asset.balanceOf(janeAddress)).to.be.equal(0);

      //// Fetch crowdfunding campaign state
      const fetchedCampaignState = await helpers.getCrowdfundingCampaignState(testData.cfManager);
      console.log("fetched crowdfunding campaign state", fetchedCampaignState);

      //// Fetch snapshot distributor state
      const fetchedSnapshotDistributorState = await helpers.getSnapshotDistributorState(snapshotDistributor);
      console.log("fetched snapshot distributor state", fetchedSnapshotDistributorState);

      //// Fetch all the Issuer instances ever deployed
      const fetchedIssuerInstances = await helpers.fetchIssuerInstances(testData.issuerFactory);
      console.log("fetched issuer instances", fetchedIssuerInstances);
      
      //// Fetch all the Asset instances ever deployed
      const fetchedAssetInstances = await helpers.fetchAssetInstances(testData.assetFactory, ASSET_TYPE);
      console.log("fetched asset instances", fetchedAssetInstances);

      //// Fetch all the Asset instances for one Issuer
      const fetchedAssetInstancesForIssuer =
          await helpers.fetchAssetInstancesForIssuer(testData.assetFactory, ASSET_TYPE, testData.issuer);
      console.log("fetched asset instances for issuer", fetchedAssetInstancesForIssuer);

      //// Fetch all the Crowdfunding Campaign instances ever deployed
      const fetchedCampaignInstances = await helpers.fetchCrowdfundingInstances(testData.cfManagerFactory, CAMPAIGN_TYPE);
      console.log("fetched crowdfunding instances", fetchedCampaignInstances);

      //// Fetch all the Crowdfunding Campaign instances for one Issuer
      const fetchedCampaignInstancesForIssuer =
          await helpers.fetchCrowdfundingInstancesForIssuer(testData.cfManagerFactory, CAMPAIGN_TYPE, testData.issuer);
      console.log("fetched campaign instances for issuer", fetchedCampaignInstancesForIssuer);

      //// Fetch all the Crowdfunding Campaign instances for one Asset
      const fetchedCampaignInstancesForAsset =
          await helpers.fetchCrowdfundingInstancesForAsset(testData.cfManagerFactory, CAMPAIGN_TYPE, testData.asset);
      console.log("fetched campaign instances for asset", fetchedCampaignInstancesForAsset);

     //// Fetch all the SnapshotDistributors ever deployed
     const fetchedSnapshotDistributorInstances = await helpers.fetchSnapshotDistributorInstances(testData.snapshotDistributorFactory);
     console.log("fetched SnapshotDistributor instances", fetchedSnapshotDistributorInstances);

     //// Fetch all the SnapshotDistributors for one Issuer
     const fetchedSnapshotDistributorInstancesForIssuer =
         await helpers.fetchSnapshotDistributorInstancesForIssuer(testData.snapshotDistributorFactory, testData.issuer);
     console.log("fetched SnapshotDistributors instances for issuer", fetchedSnapshotDistributorInstancesForIssuer);

     //// Fetch all the SnapshotDistributors for one Asset
     const fetchedSnapshotDistributorInstancesForAsset =
         await helpers.fetchSnapshotDistributorInstancesForAsset(testData.snapshotDistributorFactory, testData.asset);
     console.log("fetched SnapshotDistributors instances for asset", fetchedSnapshotDistributorInstancesForAsset);
  
      //// Fetch Issuer instance by id
      const fetchedIssuerById = await helpers.fetchIssuerStateById(testData.issuerFactory, 0);
      console.log("fetched issuer for id=0", fetchedIssuerById);

      //// Fetch Asset instance by id
      const fetchedAssetById = await helpers.fetchAssetStateById(testData.assetTransferableFactory, ASSET_TYPE, 0);
      console.log("fetched asset for id=0", fetchedAssetById);

      //// Fetch Crowdfunding campaign instance by id
      const fetchedCampaignById = await helpers.fetchCampaignStateById(testData.cfManagerFactory, CAMPAIGN_TYPE, 0);
      console.log("fetched campaign for id=0", fetchedCampaignById);

     //// Fetch SnapshotDistributor instance by id
     const fetchedSnapshotDistributorById =
         await helpers.fetchSnapshotDistributorStateById(testData.snapshotDistributorFactory, 0);
     console.log("fetched SnapshotDistributors for id=0", fetchedSnapshotDistributorById);

      //// Fetch alice tx history
      const aliceTxHistory = await helpers.fetchTxHistory(
          aliceAddress, testData.issuer, testData.cfManagerFactory, CAMPAIGN_TYPE, testData.assetFactory, ASSET_TYPE, testData.snapshotDistributorFactory
      );
      console.log("Alice tx history", aliceTxHistory);

      //// Fetch jane tx history
      const janeTxHistory = await helpers.fetchTxHistory(
          janeAddress, testData.issuer, testData.cfManagerFactory, CAMPAIGN_TYPE, testData.assetFactory, ASSET_TYPE, testData.snapshotDistributorFactory
      );
      console.log("Alice tx history", janeTxHistory);

      //// Fetch issuer approved wallets
      const walletRecords = await helpers.fetchWalletRecords(testData.issuer);
      console.log("Wallet records", walletRecords);

      //// Fetch campaigns for issuer
      const campaignStates = await helpers.queryCampaignsForIssuer(
          testData.queryService, testData.cfManagerFactory, testData.issuer, testData.nameRegistry
      );
      console.log("Campaign states", campaignStates);

      //// Fetch campaigns for issuer and investor
      const campaignStatesForInvestor = await helpers.queryCampaignsForIssuerInvestor(
          testData.queryService, testData.cfManagerFactory, testData.issuer, aliceAddress, testData.nameRegistry
      );
      console.log("Campaign states for investor", campaignStatesForInvestor);
    }
  );

});

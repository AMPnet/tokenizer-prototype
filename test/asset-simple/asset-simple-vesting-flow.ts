// @ts-ignore
import { ethers } from "hardhat";
import { expect } from "chai";
import * as helpers from "../../util/helpers";
import { TestData } from "../TestData";
import { BigNumber } from "ethers";
import { advanceBlockTime } from "../../util/utils";

describe("Asset simple - full test with vesting schedule", function () {

  const testData = new TestData()

  beforeEach(async function () {
    await testData.deploy()
  });

  it(
    `should successfully complete the flow:\n
          1)create Issuer + AssetSimple + VestingCampaign using deployer service
          2)successfully fund the project with two different investors
          3)start vesting with instant unlock of all of the tokens (0 seconds vesting)
          4)investors claim their tokens (100% of the vested amount)
    `,
    async function () {
      const ASSET_TYPE = "AssetSimple";
      const CAMPAIGN_TYPE = "CfManagerSoftcapVesting";
      await testData.deployIssuerAssetSimpleCampaignVesting()

      //// Alice buys $100k USDC and goes through kyc process (wallet approved)
      const aliceAddress = await testData.alice.getAddress();
      const aliceInvestment = 100000;
      const aliceInvestmentWei = ethers.utils.parseEther(aliceInvestment.toString());
      await testData.stablecoin.transfer(aliceAddress, aliceInvestmentWei);
      await testData.walletApproverService.connect(testData.walletApprover)
          .approveWallet(testData.issuer.address, aliceAddress);

      //// Alice invests $100k USDC in the project
      await helpers.invest(testData.alice, testData.cfManagerVesting, testData.stablecoin, aliceInvestment);

      //// Jane buys $100k USDC and goes through kyc process (wallet approved)
      const janeAddress = await testData.jane.getAddress();
      const janeInvestment = 100000;
      const janeInvestmentWei: BigNumber = ethers.utils.parseEther(janeInvestment.toString());
      await testData.stablecoin.transfer(janeAddress, janeInvestmentWei);
      await testData.walletApproverService.connect(testData.walletApprover)
          .approveWallet(testData.issuer.address, janeAddress);
    
      //// Jane invests $100k USDC in the project and then cancels her investment and then invests again
      await helpers.invest(testData.jane, testData.cfManagerVesting, testData.stablecoin, janeInvestment);
      await helpers.cancelInvest(testData.jane, testData.cfManagerVesting);
      await helpers.invest(testData.jane, testData.cfManagerVesting, testData.stablecoin, janeInvestment);

      // Asset owner finalizes the campaign as the soft cap has been reached and starts the vesting campaign.
      await testData.cfManagerVesting.connect(testData.issuerOwner).finalize();
      const now = parseInt((Number((new Date()).valueOf()) / 1000).toString());
      
      await testData.cfManagerVesting.connect(testData.issuerOwner).startVesting(now, 0, 30);
      await advanceBlockTime(now + 50);

      // Alice has to claim tokens after the campaign has been closed successfully
      await testData.cfManagerVesting.connect(testData.alice).claim(aliceAddress);
      expect(await testData.asset.balanceOf(aliceAddress)).to.be.equal(aliceInvestmentWei); // 1 token = $1

      // Jane has to claim tokens after the campaign has been closed successfully
      await testData.cfManagerVesting.connect(testData.jane).claim(janeAddress);
      expect(await testData.asset.balanceOf(janeAddress)).to.be.equal(janeInvestmentWei); // 1 token = $1
      
      //// Fetch crowdfunding campaign state
      const fetchedCampaignState = await helpers.getCrowdfundingCampaignState(testData.cfManagerVesting);
      console.log("fetched crowdfunding campaign state", fetchedCampaignState);

      //// Fetch all the Issuer instances ever deployed
      const fetchedIssuerInstances = await helpers.fetchIssuerInstances(testData.issuerFactory);
      console.log("fetched issuer instances", fetchedIssuerInstances);
      
      //// Fetch all the Asset instances ever deployed
      const fetchedAssetInstances = await helpers.fetchAssetInstances(testData.assetSimpleFactory, ASSET_TYPE);
      console.log("fetched asset instances", fetchedAssetInstances);

      //// Fetch all the Asset instances for one Issuer
      const fetchedAssetInstancesForIssuer =
          await helpers.fetchAssetInstancesForIssuer(testData.assetSimpleFactory, ASSET_TYPE, testData.issuer);
      console.log("fetched asset instances for issuer", fetchedAssetInstancesForIssuer);

      //// Fetch all the Crowdfunding Campaign instances ever deployed
      const fetchedCampaignInstances = await helpers.fetchCrowdfundingInstances(testData.cfManagerVestingFactory, CAMPAIGN_TYPE);
      console.log("fetched crowdfunding instances", fetchedCampaignInstances);

      //// Fetch all the Crowdfunding Campaign instances for one Issuer
      const fetchedCampaignInstancesForIssuer =
          await helpers.fetchCrowdfundingInstancesForIssuer(testData.cfManagerVestingFactory, CAMPAIGN_TYPE, testData.issuer);
      console.log("fetched campaign instances for issuer", fetchedCampaignInstancesForIssuer);

      //// Fetch all the Crowdfunding Campaign instances for one Asset
      const fetchedCampaignInstancesForAsset =
          await helpers.fetchCrowdfundingInstancesForAsset(testData.cfManagerVestingFactory, CAMPAIGN_TYPE, testData.asset);
      console.log("fetched campaign instances for asset", fetchedCampaignInstancesForAsset);

      //// Fetch Issuer instance by id
      const fetchedIssuerById = await helpers.fetchIssuerStateById(testData.issuerFactory, 0);
      console.log("fetched issuer for id=0", fetchedIssuerById);

      //// Fetch Asset instance by id
      const fetchedAssetById = await helpers.fetchAssetStateById(testData.assetSimpleFactory, ASSET_TYPE, 0);
      console.log("fetched asset for id=0", fetchedAssetById);

      //// Fetch Crowdfunding campaign instance by id
      const fetchedCampaignById = await helpers.fetchCampaignStateById(testData.cfManagerVestingFactory, CAMPAIGN_TYPE, 0);
      console.log("fetched campaign for id=0", fetchedCampaignById);

      //// Fetch alice tx history
      const aliceTxHistory = await helpers.fetchTxHistory(
          aliceAddress, testData.issuer, testData.cfManagerVestingFactory, CAMPAIGN_TYPE, testData.assetSimpleFactory, ASSET_TYPE, testData.snapshotDistributorFactory
      );
      console.log("Alice tx history", aliceTxHistory);

      //// Fetch jane tx history
      const janeTxHistory = await helpers.fetchTxHistory(
          janeAddress, testData.issuer, testData.cfManagerVestingFactory, CAMPAIGN_TYPE, testData.assetSimpleFactory, ASSET_TYPE, testData.snapshotDistributorFactory
      );
      console.log("Alice tx history", janeTxHistory);

      //// Fetch issuer approved wallets
      const walletRecords = await helpers.fetchWalletRecords(testData.issuer);
      console.log("Wallet records", walletRecords);

      //// Fetch campaigns for issuer
      const campaignStates = await helpers.queryCampaignsForIssuer(
          testData.queryService, testData.cfManagerVestingFactory, testData.issuer, testData.nameRegistry
      );
      console.log("Campaign states", campaignStates);

      //// Fetch campaigns for issuer and investor
      const campaignStatesForInvestor = await helpers.queryCampaignsForIssuerInvestor(
          testData.queryService, testData.cfManagerVestingFactory, testData.issuer, aliceAddress, testData.nameRegistry
      );
      console.log("Campaign states for investor", campaignStatesForInvestor);
    }
  );

});

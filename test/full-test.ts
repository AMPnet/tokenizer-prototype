import { ethers } from "hardhat";
import { Contract, Signer, BigNumber } from "ethers";
import { expect } from "chai";
import * as helpers from "../util/helpers";

describe("Full test", function () {

  //////// FACTORIES ////////
  let issuerFactory: Contract;
  let assetFactory: Contract;
  let cfManagerFactory: Contract;
  let payoutManagerFactory: Contract;

  //////// SERVICES ////////
  let walletApproverService: Contract;
  let deployerService: Contract;

  //////// SIGNERS ////////
  let deployer: Signer;
  let issuerOwner: Signer;
  let alice: Signer;
  let jane: Signer;
  let frank: Signer;
  let walletApprover: Signer

  //////// CONTRACTS ////////
  let stablecoin: Contract;
  let issuer: Contract;
  let asset: Contract;
  let cfManager: Contract;

  beforeEach(async function () {
    const accounts: Signer[] = await ethers.getSigners();
    deployer        = accounts[0];
    issuerOwner     = accounts[1];
    alice           = accounts[3];
    jane            = accounts[4];
    frank           = accounts[5];
    walletApprover  = accounts[6];

    stablecoin = await helpers.deployStablecoin(deployer, "1000000000000");
    
    const factories = await helpers.deployFactories(deployer);
    issuerFactory = factories[0];
    assetFactory = factories[1];
    cfManagerFactory = factories[2];
    payoutManagerFactory = factories[3];

    const walletApproverAddress = await walletApprover.getAddress();
    const services = await helpers.deployServices(
      deployer,
      walletApproverAddress,
      "0.001"
    );
    walletApproverService = services[0];
    deployerService = services[1];
  });

  it(
    `should successfully complete the flow:\n
          1)create Issuer\n
          2)create crowdfunding campaign\n
          3)successfully fund the project
    `,
    async function () {
      //// Set the config for Issuer, Asset and Crowdfunding Campaign 
      const issuerInfoHash = "issuer-info-ipfs-hash";
      const issuerOwnerAddress = await issuerOwner.getAddress();
      const assetName = "Test Asset";
      const assetTicker = "TSTA";
      const assetInfoHash = "asset-info-ipfs-hash";
      const assetTokenSupply = 1000000;
      const issuerWhitelistRequired = true;
      const campaignInitialPricePerToken = 10000;   // 1$ per token
      const maxTokensToBeSold = 800000;             // 800k tokens to be sold at most
      const campaignSoftCap = 400000;               // minimum $400k funds raised has to be reached for campaign to succeed
      const campaignWhitelistRequired = true;       // only whitelisted wallets can invest
      const campaignInfoHash = "campaign-info-ipfs-hash";

      //// Deploy the contracts with the provided config
      const contracts = await helpers.createIssuerAssetCampaign(
        issuerOwnerAddress,
        stablecoin.address,
        walletApproverService.address,
        issuerInfoHash,
        issuerOwnerAddress,
        assetTokenSupply,
        issuerWhitelistRequired,
        assetName,
        assetTicker,
        assetInfoHash,
        issuerOwnerAddress,
        campaignInitialPricePerToken,
        campaignSoftCap,
        maxTokensToBeSold,
        campaignWhitelistRequired,
        campaignInfoHash,
        issuerFactory,
        assetFactory,
        cfManagerFactory,
        deployerService
      );
      issuer = contracts[0];
      asset = contracts[1];
      cfManager = contracts[2];

      //// Alice buys $400k USDC and goes through kyc process (wallet approved)
      const aliceAddress = await alice.getAddress();
      const aliceInvestment = 400000;
      const aliceInvestmentWei = ethers.utils.parseEther(aliceInvestment.toString());
      await stablecoin.transfer(aliceAddress, aliceInvestmentWei);
      await walletApproverService.connect(walletApprover).approveWallet(issuer.address, aliceAddress);
      
      //// Alice invests $400k USDC in the project
      await helpers.invest(alice, cfManager, stablecoin, aliceInvestmentWei);

      //// Jane buys $20k USDC and goes through kyc process (wallet approved)
      const janeAddress = await jane.getAddress();
      const janeInvestment = 20000;
      const janeInvestmentWei = ethers.utils.parseEther(janeInvestment.toString());
      await stablecoin.transfer(janeAddress, janeInvestmentWei);
      await walletApproverService.connect(walletApprover).approveWallet(issuer.address, janeAddress);
      
      //// Jane invests $20k USDC in the project and then cancels her investment
      await helpers.invest(jane, cfManager, stablecoin, janeInvestmentWei);
      await helpers.cancelInvest(jane, cfManager);

      // Asset owner finalizes the campaign as the soft cap has been reached.
      await cfManager.connect(issuerOwner).finalize();
      
      // Alice has to claim tokens after the campaign has been closed successfully
      await cfManager.connect(alice).claim(aliceAddress);

      //// Owner creates payout manager, updates info once
      const payoutManagerInfoHash = "payout-manager-info-hash";
      const updatedPayoutManagerInfoHash = "updated-payout-manager-info-hash";
      const payoutManager = await helpers.createPayoutManager(
        issuerOwnerAddress,
        asset,
        payoutManagerInfoHash,
        payoutManagerFactory
      );
      await helpers.setInfo(issuerOwner, payoutManager, updatedPayoutManagerInfoHash);

      //// Distribute $100k revenue to the token holders using the payout manager from the step before
      const payoutDescription = "WindFarm Mexico Q3/2021 revenue";
      const revenueAmount = 100000;
      const revenueAmountWei = ethers.utils.parseEther(revenueAmount.toString());
      const issuerAddress = await issuerOwner.getAddress();
      await stablecoin.transfer(issuerAddress, revenueAmountWei); 
      await helpers.createPayout(issuerOwner, payoutManager, stablecoin, revenueAmount, payoutDescription)

      //// Alice claims her revenue share by calling previously created PayoutManager contract and providing the payoutId param (0 in this case)
      //// PayoutManager address has to be known upfront (can be found for one asset by scanning PayoutManagerCreated event for asset address)
      const payoutId = 1;
      const aliceBalanceBeforePayout = await stablecoin.balanceOf(aliceAddress);
      expect(aliceBalanceBeforePayout).to.be.equal(0);
      await helpers.claimRevenue(alice, payoutManager, payoutId)
      const aliceBalanceAfterPayout = await stablecoin.balanceOf(aliceAddress);
      expect(aliceBalanceAfterPayout).to.be.equal(revenueAmountWei.mul(40).div(100)); // alice claims 40% of total revenue
    
      //// Fetch issuer state
      const fetchedIssuerState = await helpers.getIssuerState(issuer);
      console.log("fetched issuer state", fetchedIssuerState);

      //// Fetch asset state
      const fetchedAssetState = await helpers.getAssetState(asset);
      console.log("fetched asset state", fetchedAssetState);

      //// Fetch crowdfunding campaign state
      const fetchedCampaignState = await helpers.getCrowdfundingCampaignState(cfManager);
      console.log("fetched crowdfunding campaign state", fetchedCampaignState);

      //// Fetch payout manager state
      const fetchedPayoutManagerState = await helpers.getPayoutManagerState(payoutManager);
      console.log("fetched payout manager state", fetchedPayoutManagerState);

      //// Fetch all the Issuer instances ever deployed
      const fetchedIssuerInstances = await helpers.fetchIssuerInstances(issuerFactory);
      console.log("fetched issuer instances", fetchedIssuerInstances);
      
      //// Fetch all the Asset instances ever deployed
      const fetchedAssetInstances = await helpers.fetchAssetInstances(assetFactory);
      console.log("fetched asset instances", fetchedAssetInstances);

      //// Fetch all the Asset instances for one Issuer
      const fetchedAssetInstancesForIssuer = await helpers.fetchAssetInstancesForIssuer(assetFactory, issuer);
      console.log("fetched asset instances for issuer", fetchedAssetInstancesForIssuer);

      //// Fetch all the Crowdfunding Campaign instances ever deployed
      const fetchedCampaignInstances = await helpers.fetchCrowdfundingInstances(cfManagerFactory);
      console.log("fetched crowdfunding instances", fetchedCampaignInstances);

      //// Fetch all the Crowdfunding Campaign instances for one Issuer
      const fetchedCampaignInstancesForIssuer = await helpers.fetchCrowdfundingInstancesForIssuer(cfManagerFactory, issuer);
      console.log("fetched campaign instances for issuer", fetchedCampaignInstancesForIssuer);

      //// Fetch all the Crowdfunding Campaign instances for one Asset
      const fetchedCampaignInstancesForAseet = await helpers.fetchCrowdfundingInstancesForAsset(cfManagerFactory, asset);
      console.log("fetched campaign instances for asset", fetchedCampaignInstancesForAseet);
      
      //// Fetch all the Payout Managers ever deployed
      const fetchedPayoutManagerInstances = await helpers.fetchPayoutManagerInstances(payoutManagerFactory);
      console.log("fetched payout manager instances", fetchedPayoutManagerInstances);

      //// Fetch all the Payout Managers for one Issuer
      const fetchedPayoutManagerInstancesForIssuer = await helpers.fetchPayoutManagerInstancesForIssuer(payoutManagerFactory, issuer);
      console.log("fetched payout manager instances for issuer", fetchedPayoutManagerInstancesForIssuer);

      //// Fetch all the Payout Managers for one Asset
      const fetchedPayoutManagerInstancesForAsset = await helpers.fetchPayoutManagerInstancesForAsset(payoutManagerFactory, asset);
      console.log("fetched payout manager instances for asset", fetchedPayoutManagerInstancesForAsset);
  
      //// Fetch Issuer instance by id
      const fetchedIssuerById = await helpers.fetchIssuerStateById(issuerFactory, 0);
      console.log("fetched issuer for id=0", fetchedIssuerById);

      //// Fetch Asset instance by id
      const fetchedAssetById = await helpers.fetchAssetStateById(assetFactory, 0);
      console.log("fetched asset for id=0", fetchedAssetById);

      //// Fetch Crowdfunding campaign instance by id
      const fetchedCampaignById = await helpers.fetchCampaignStateById(cfManagerFactory, 0);
      console.log("fetched campaign for id=0", fetchedCampaignById);

      //// Fetch Payout manager instance by id
      const fetchedPayoutManagerById = await helpers.fetchPayoutManagerStateById(payoutManagerFactory, 0);
      console.log("fetched payout manager for id=0", fetchedPayoutManagerById);

      //// Fetch alice tx history
      const aliceTxHistory = await helpers.fetchTxHistory(aliceAddress, issuer, cfManagerFactory, assetFactory, payoutManagerFactory);
      console.log("Alice tx history", aliceTxHistory);

      //// Fetch jane tx history
      const janeTxHistory = await helpers.fetchTxHistory(janeAddress, issuer, cfManagerFactory, assetFactory, payoutManagerFactory);
      console.log("Alice tx history", janeTxHistory);

      //// Fetch issuer approved wallets
      const walletRecords = await helpers.fetchWalletRecords(issuer);
      console.log("Wallet records", walletRecords);

      //// Fetch issuer approved campaigns
      const campaignRecords = await helpers.fetchCampaignRecords(asset);
      console.log("Campaign records", campaignRecords);
    }
  );

});

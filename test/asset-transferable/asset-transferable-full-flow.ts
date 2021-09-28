// @ts-ignore
import { ethers } from "hardhat";
import { Contract, Signer } from "ethers";
import { expect } from "chai";
import * as helpers from "../../util/helpers";
import * as deployerServiceUtil from "../../util/deployer-service";

describe("Full test", function () {

  //////// FACTORIES ////////
  let issuerFactory: Contract;
  let assetFactory: Contract;
  let assetTransferableFactory: Contract;
  let cfManagerFactory: Contract;
  let snapshotDistributorFactory: Contract;

  //////// SERVICES ////////
  let walletApproverService: Contract;
  let deployerService: Contract;
  let queryService: Contract;

  ////////// REGISTRIES //////////
  let apxRegistry: Contract;
  let nameRegistry: Contract;

  //////// SIGNERS ////////
  let deployer: Signer;
  let assetManager: Signer;
  let priceManager: Signer;
  let walletApprover: Signer;
  let issuerOwner: Signer;
  let alice: Signer;
  let jane: Signer;
  let frank: Signer;
  let mark: Signer;

  //////// CONTRACTS ////////
  let stablecoin: Contract;
  let issuer: Contract;
  let asset: Contract;
  let cfManager: Contract;

  beforeEach(async function () {
    const accounts: Signer[] = await ethers.getSigners();
    
    deployer        = accounts[0];
    assetManager    = accounts[1];
    priceManager    = accounts[2];
    walletApprover  = accounts[3];

    issuerOwner     = accounts[4];
    alice           = accounts[5];
    jane            = accounts[6];
    frank           = accounts[7];
    mark            = accounts[8];

    stablecoin = await helpers.deployStablecoin(deployer, "1000000000000");
    
    const factories = await helpers.deployFactories(deployer);
    issuerFactory = factories[0];
    assetFactory = factories[1];
    assetTransferableFactory = factories[2];
    cfManagerFactory = factories[3];
    snapshotDistributorFactory = factories[4];

    apxRegistry = await helpers.deployApxRegistry(
      deployer, 
      await deployer.getAddress(), 
      await assetManager.getAddress(), 
      await priceManager.getAddress()
    );
    nameRegistry = await helpers.deployNameRegistry(
      deployer,
      await deployer.getAddress(),
      factories.map(factory => factory.address)
    );

    const walletApproverAddress = await walletApprover.getAddress();
    const services = await helpers.deployServices(
      deployer,
      walletApproverAddress,
      "0.001"
    );
    walletApproverService = services[0];
    deployerService = services[1];
    queryService = services[2];
  });

  it(
    `should successfully complete the flow:\n
          1)create Issuer + AssetTransferable + Campaign using deployer service\n
          2)successfully fund the project with two different investors
          3)update asset price
          4)liquidate asset with the correct price: max(crowdfunding campaign price, market price)
          5)investors claim liquidation funds. asset owner ownes 100% of the supply
    `,
    async function () {
      //// Set the config for Issuer, Asset and Crowdfunding Campaign
      const issuerMappedName = "test-issuer";
      const issuerInfoHash = "issuer-info-ipfs-hash";
      const issuerOwnerAddress = await issuerOwner.getAddress();
      const assetName = "Test Asset";
      const assetMappedName = "test-asset";
      const assetTicker = "TSTA";
      const assetInfoHash = "asset-info-ipfs-hash";
      const assetWhitelistRequiredForRevenueClaim = true;
      const assetWhitelistRequiredForLiquidationClaim = true;
      const assetTokenSupply = 300000;              // 300k tokens total supply
      const campaignInitialPricePerToken = 10000;   // 1$ per token
      const maxTokensToBeSold = 200000;             // 200k tokens to be sold at most (200k $$$ to be raised at most)
      const campaignSoftCap = 100000;               // minimum $100k funds raised has to be reached for campaign to succeed
      const campaignMinInvestment = 10000;          // $10k min investment per user
      const campaignMaxInvestment = 400000;         // $200k max investment per user
      const campaignWhitelistRequired = true;       // only whitelisted wallets can invest
      const campaignMappedName = "test-campaign";
      const campaignInfoHash = "campaign-info-ipfs-hash";
      const childChainManager = ethers.Wallet.createRandom().address;

      //// Deploy the contracts with the provided config
      issuer = await helpers.createIssuer(
        issuerOwnerAddress,
        issuerMappedName,
        stablecoin,
        walletApproverService.address,
        issuerInfoHash,
        issuerFactory,
        nameRegistry
      );
      const contracts = await deployerServiceUtil.createAssetTransferableCampaign(
        issuer,
        issuerOwnerAddress,
        assetMappedName,
        assetTokenSupply,
        assetWhitelistRequiredForRevenueClaim,
        assetWhitelistRequiredForLiquidationClaim,
        assetName,
        assetTicker,
        assetInfoHash,
        issuerOwnerAddress,
        campaignMappedName,
        campaignInitialPricePerToken,
        campaignSoftCap,
        campaignMinInvestment,
        campaignMaxInvestment,
        maxTokensToBeSold,
        campaignWhitelistRequired,
        campaignInfoHash,
        apxRegistry.address,
        nameRegistry.address,
        childChainManager,
        assetTransferableFactory,
        cfManagerFactory,
        deployerService
      );
      asset = contracts[0];
      cfManager = contracts[1];

      //// Alice buys $100k USDC and goes through kyc process (wallet approved)
      const aliceAddress = await alice.getAddress();
      const aliceInvestment = 100000;
      const aliceInvestmentWei = ethers.utils.parseEther(aliceInvestment.toString());
      await stablecoin.transfer(aliceAddress, aliceInvestmentWei);
      await walletApproverService.connect(walletApprover).approveWallet(issuer.address, aliceAddress);

      //// Alice invests $100k USDC in the project
      await helpers.invest(alice, cfManager, stablecoin, aliceInvestment);

      //// Jane buys $100k USDC and goes through kyc process (wallet approved)
      const janeAddress = await jane.getAddress();
      const janeInvestment = 100000;
      const janeInvestmentWei = ethers.utils.parseEther(janeInvestment.toString());
      await stablecoin.transfer(janeAddress, janeInvestmentWei);
      await walletApproverService.connect(walletApprover).approveWallet(issuer.address, janeAddress);
    
      //// Jane invests $100k USDC in the project and then cancels her investment and then invests again
      await helpers.invest(jane, cfManager, stablecoin, janeInvestment);
      await helpers.cancelInvest(jane, cfManager);
      await helpers.invest(jane, cfManager, stablecoin, janeInvestment);

      // Asset owner finalizes the campaign as the soft cap has been reached.
      await cfManager.connect(issuerOwner).finalize();
      
      // Alice has to claim tokens after the campaign has been closed successfully
      await cfManager.connect(alice).claim(aliceAddress);
      // Jane has to claim tokens after the campaign has been closed successfully
      await cfManager.connect(jane).claim(janeAddress);

      //// Owner creates snapshot distributor, updates info once
      const snapshotDistributorMappedName = "snapshot-distributor";
      const snapshotDistributorInfoHash = "snapshot-distributor-info-hash";
      const updatedSnapshotDistributorInfoHash = "updated-snapshot-distributor-info-hash";
      const snapshotDistributor = await helpers.createSnapshotDistributor(
        issuerOwnerAddress,
        snapshotDistributorMappedName,
        asset,
        snapshotDistributorInfoHash,
        snapshotDistributorFactory,
        nameRegistry
      );
      await helpers.setInfo(issuerOwner, snapshotDistributor, updatedSnapshotDistributorInfoHash);

      //// Distribute $100k revenue to the token holders using the snapshot distributor from the step before
      const payoutDescription = "WindFarm Mexico Q3/2021 revenue";
      const revenueAmount = 300000;
      const revenueAmountWei = ethers.utils.parseEther(revenueAmount.toString());
      const issuerAddress = await issuerOwner.getAddress();
      await stablecoin.transfer(issuerAddress, revenueAmountWei);
      console.log("issuer balance before share payout: ", ethers.utils.formatEther(await stablecoin.balanceOf(issuerAddress)));
      await helpers.createPayout(issuerOwner, snapshotDistributor, stablecoin, revenueAmount, payoutDescription)
      console.log("issuer balance after share payout: ", ethers.utils.formatEther(await stablecoin.balanceOf(issuerAddress)));

      //// Alice claims her revenue share by calling previously created SnapshotDistributor contract and providing the payoutId param (0 in this case)
      //// SnapshotDistributor address has to be known upfront (can be found for one asset by scanning SnapshotDistributorCreated event for asset address)
      const snapshotId = 1;
      const aliceBalanceBeforePayout = await stablecoin.balanceOf(aliceAddress);
      expect(aliceBalanceBeforePayout).to.be.equal(0);
      const aliceRevenueShareWei = ethers.utils.parseEther("100000");    // (1/3) of the total revenue payed out
      await helpers.claimRevenue(alice, snapshotDistributor, snapshotId)
      const aliceBalanceAfterPayout = await stablecoin.balanceOf(aliceAddress);
      expect(aliceBalanceAfterPayout).to.be.equal(aliceRevenueShareWei); // alice claims (1/3) of total revenue
      console.log("Alice total balance", await stablecoin.balanceOf(aliceAddress));

      //// Jane claims her revenue share by calling previously created SnapshotDistributor contract and providing the payoutId param (0 in this case)
      //// SnapshotDistributor address has to be known upfront (can be found for one asset by scanning SnapshotDistributorCreated event for asset address)
      const janeBalanceBeforePayout = await stablecoin.balanceOf(janeAddress);
      expect(janeBalanceBeforePayout).to.be.equal(0);
      const janeRevenueShareWei = ethers.utils.parseEther("100000");    // (1/3) of the total revenue payed out
      await helpers.claimRevenue(jane, snapshotDistributor, snapshotId);
      const janeBalanceAfterPayout = await stablecoin.balanceOf(janeAddress);
      expect(janeBalanceAfterPayout).to.be.equal(janeRevenueShareWei); // jane claims (1/3) of total revenue
      console.log("Jane total balance", await stablecoin.balanceOf(janeAddress));

      //// Asset is registered on the APX Registry and the market price is updated
      await helpers.registerAsset(assetManager, apxRegistry, asset.address, asset.address);
      // update market price for asset
      // price: $0.70, expiry: 60 seconds
      await helpers.updatePrice(priceManager, apxRegistry, asset, 11000, 60);
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
      await stablecoin.transfer(issuerOwnerAddress, ethers.utils.parseEther("20000"));
      const liquidatorBalanceBeforeLiquidation = await stablecoin.balanceOf(issuerAddress);
      expect (liquidatorBalanceBeforeLiquidation).to.be.equal(ethers.utils.parseEther(liquidationAmount.toString()));
      await helpers.liquidate(issuerOwner, asset, stablecoin, liquidationAmount);
      const liquidatorBalanceAfterLiquidation = await stablecoin.balanceOf(issuerAddress);
      expect (liquidatorBalanceAfterLiquidation).to.be.equal(0);
      const assetTotalSupply = await asset.totalSupply();
      expect(await (asset.balanceOf(issuerOwnerAddress))).to.be.equal(assetTotalSupply);

      //// Alice claims liquidation share
      const aliceLiquidationShare = 110000;
      const aliceLiquidationShareWei = ethers.utils.parseEther(aliceLiquidationShare.toString());
      await helpers.claimLiquidationShare(alice, asset);
      const aliceBalanceAfterLiquidationClaim = await stablecoin.balanceOf(aliceAddress);
      expect(aliceBalanceAfterLiquidationClaim).to.be.equal(aliceRevenueShareWei.add(aliceLiquidationShareWei));
      expect(await asset.balanceOf(aliceAddress)).to.be.equal(0);

      //// Jane claims liquidation share
      const janeLiquidationShare = 110000;
      const janeLiquidationShareWei = ethers.utils.parseEther(janeLiquidationShare.toString());
      await helpers.claimLiquidationShare(jane, asset);
      const janeBalanceAfterLiquidationClaim = await stablecoin.balanceOf(janeAddress);
      expect(janeBalanceAfterLiquidationClaim).to.be.equal(janeRevenueShareWei.add(janeLiquidationShareWei));
      expect(await asset.balanceOf(janeAddress)).to.be.equal(0);

      //// Fetch issuer state
      const fetchedIssuerState = await helpers.getIssuerState(issuer);
      console.log("fetched issuer state", fetchedIssuerState);

      //// Fetch asset state
      const fetchedAssetState = await helpers.getAssetState(asset);
      console.log("fetched asset state", fetchedAssetState);
      const oldChildChainManager = await helpers.getAssetChildChainManager(asset);
      expect(oldChildChainManager).to.be.equal(childChainManager);
      const newChildChainManager = await ethers.Wallet.createRandom().getAddress();
      await helpers.setChildChainManager(issuerOwner, asset, newChildChainManager);
      const fetchedChildChainManager = await helpers.getAssetChildChainManager(asset);
      expect(fetchedChildChainManager).to.be.equal(newChildChainManager);
      
      //// Fetch crowdfunding campaign state
      const fetchedCampaignState = await helpers.getCrowdfundingCampaignState(cfManager);
      console.log("fetched crowdfunding campaign state", fetchedCampaignState);

      //// Fetch snapshot distributor state
      const fetchedSnapshotDistributorState = await helpers.getSnapshotDistributorState(snapshotDistributor);
      console.log("fetched snapshot distributor state", fetchedSnapshotDistributorState);

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
      
      //// Fetch all the Snapshot Distributor ever deployed
      const fetchedSnapshotDistributorInstances = await helpers.fetchSnapshotDistributorInstances(snapshotDistributorFactory);
      console.log("fetched snapshot distributor instances", fetchedSnapshotDistributorInstances);

      //// Fetch all the Snapshot Distributor for one Issuer
      const fetchedSnapshotDistributorInstancesForIssuer = await helpers.fetchSnapshotDistributorInstancesForIssuer(snapshotDistributorFactory, issuer);
      console.log("fetched snapshot distributor instances for issuer", fetchedSnapshotDistributorInstancesForIssuer);

      //// Fetch all the Snapshot Distributor for one Asset
      const fetchedSnapshotDistributorInstancesForAsset = await helpers.fetchSnapshotDistributorInstancesForAsset(snapshotDistributorFactory, asset);
      console.log("fetched snbapshot distributor instances for asset", fetchedSnapshotDistributorInstancesForAsset);
  
      //// Fetch Issuer instance by id
      const fetchedIssuerById = await helpers.fetchIssuerStateById(issuerFactory, 0);
      console.log("fetched issuer for id=0", fetchedIssuerById);

      //// Fetch Asset instance by id
      const fetchedAssetById = await helpers.fetchAssetTransferableStateById(assetTransferableFactory, 0);
      console.log("fetched asset for id=0", fetchedAssetById);

      //// Fetch Crowdfunding campaign instance by id
      const fetchedCampaignById = await helpers.fetchCampaignStateById(cfManagerFactory, 0);
      console.log("fetched campaign for id=0", fetchedCampaignById);

      //// Fetch SnapshotDistributor instance by id
      const fetchedSnapshotDistributorById = await helpers.fetchSnapshotDistributorStateById(snapshotDistributorFactory, 0);
      console.log("fetched snapshot distributor for id=0", fetchedSnapshotDistributorById);

      //// Fetch alice tx history
      const aliceTxHistory = await helpers.fetchTxHistory(aliceAddress, issuer, cfManagerFactory, assetFactory, snapshotDistributorFactory);
      console.log("Alice tx history", aliceTxHistory);

      //// Fetch jane tx history
      const janeTxHistory = await helpers.fetchTxHistory(janeAddress, issuer, cfManagerFactory, assetFactory, snapshotDistributorFactory);
      console.log("Alice tx history", janeTxHistory);

      //// Fetch issuer approved wallets
      const walletRecords = await helpers.fetchWalletRecords(issuer);
      console.log("Wallet records", walletRecords);

      //// Fetch campaigns for issuer
      const campaignStates = await helpers.queryCampaignsForIssuer(queryService, cfManagerFactory, issuer, nameRegistry);
      console.log("Campaign states", campaignStates);

      //// Fetch campaigns for issuer and investor
      const campaignStatesForInvestor = await helpers.queryCampaignsForIssuerInvestor(queryService, cfManagerFactory, issuer, aliceAddress, nameRegistry);
      console.log("Campaign states for investor", campaignStatesForInvestor);
    
    }
  );

});

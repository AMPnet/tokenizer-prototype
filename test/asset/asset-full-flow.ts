// @ts-ignore
import { ethers } from "hardhat";
import { expect } from "chai";
import * as helpers from "../../util/helpers";
import {TestData} from "../TestData";

describe("Asset - full test", function () {

  const testData = new TestData()

  beforeEach(async function () {
    await testData.deploy()
  });

  it(
    `should successfully complete the flow:\n
          1)create Issuer + Asset + Campaign using deployer service
          2)successfully fund the project with two different investors
          3)update asset price
          4)liquidate asset with the correct price: max(crowdfunding campaign price, market price)
          5)investors claim liquidation funds. asset owner ownes 100% of the supply
    `,
    async function () {
      const ASSET_TYPE = "Asset";
      const CAMPAIGN_TYPE = "CfManagerSoftcap";
      const issuerOwnerAddress = await testData.issuerOwner.getAddress();
      const treasuryAddress = await testData.treasury.getAddress();
      await testData.deployIssuerAssetClassicCampaign()

      //// Frank buys $100k USDC
      const frankAddress = await testData.frank.getAddress(); 
      const aliceInvestment = 100000;
      const aliceInvestmentWei = await helpers.parseStablecoin(aliceInvestment, testData.stablecoin);
      await testData.stablecoin.transfer(frankAddress, aliceInvestmentWei);

      //// Alice goes through kyc process (wallet approved)
      const aliceAddress = await testData.alice.getAddress();
      await testData.walletApproverService.connect(testData.walletApprover)
          .approveWallet(testData.issuer.address, aliceAddress);

      //// Frank spends $100k to invest in the Alice's name. Should succeed: alice is approved and frank wallet is funded
      await helpers.investForBeneficiary(
          testData.frank,
          testData.alice,
          testData.cfManager,
          testData.stablecoin,
          aliceInvestment,
          testData.frank
      );

      ///// Alice tries to invest for Mark's unapproved wallet. Tx should fail.
      await expect(
          helpers.investForBeneficiary(
              testData.alice,
              testData.mark,
              testData.cfManager,
              testData.stablecoin,
              aliceInvestment,
              testData.alice
          )
      ).to.be.revertedWith("ACfManager: Wallet not whitelisted.");

      //// Jane buys $50k USDC (and another 50k$ to give back to the owner) and goes through kyc process (wallet approved)
      //// Jane will send $50k worth of the tokens back to the owner to test if the tokens are transferable.
      //// This asset type forbids token transfer in general, but allows sending tokens to the asset owner.
      const janeAddress = await testData.jane.getAddress();
      const janeInvestment = 50000;
      const janeAdditionalInvestment = 50000;
      const janeTotalInvestment = janeInvestment + janeAdditionalInvestment;
      const janeInvestmentWei = await helpers.parseStablecoin((janeTotalInvestment).toString(), testData.stablecoin);
      await testData.stablecoin.transfer(janeAddress, janeInvestmentWei);
      await testData.walletApproverService.connect(testData.walletApprover)
          .approveWallet(testData.issuer.address, janeAddress);

      //// Jane invests $50k + $50k. The additional $50k of tokens will be transferred back to the project owner wallet
      //// Cancel invest is called one time before investing again to check if the cancel investment process works well.
      await helpers.invest(testData.jane, testData.cfManager, testData.stablecoin, janeTotalInvestment);
      expect(await testData.stablecoin.balanceOf(janeAddress)).to.be.equal(0);
      await helpers.cancelInvest(testData.jane, testData.cfManager);
      expect(
          await testData.stablecoin.balanceOf(janeAddress)
      ).to.be.equal(await helpers.parseStablecoin(janeTotalInvestment, testData.stablecoin));
      await helpers.invest(testData.jane, testData.cfManager, testData.stablecoin, janeTotalInvestment);

      //// Asset owner finalizes the campaign as the soft cap has been reached. Campaign fee is 10%.
      //// This tests the case when the default fee (1/5 = 20%) is overriden by the per-campaign-basis fee (1/10 = 10%).
      const feeNumerator = 1;
      const feeDenominator = 10;
      const totalInvestment = janeInvestmentWei.add(aliceInvestmentWei); 
      const totalFee = totalInvestment.mul(feeNumerator).div(feeDenominator);
      const fundsRaisedWei = totalInvestment.sub(totalFee);
      const stablecoinPrecision = await testData.stablecoin.decimals();
      const fundsRaised = await ethers.utils.formatUnits(fundsRaisedWei, stablecoinPrecision);
      await helpers.setDefaultFee(testData.feeManager, 1, 5);
      await helpers.setFeeForCampaign(testData.feeManager, testData.cfManager.address, feeNumerator, feeDenominator);
      await testData.cfManager.connect(testData.issuerOwner).finalize();
      expect(
          await testData.stablecoin.balanceOf(issuerOwnerAddress)
      ).to.be.equal(totalInvestment.sub(totalFee));
      expect(
          await testData.stablecoin.balanceOf(treasuryAddress)
      ).to.be.equal(totalFee);

      //// Alice has to claim tokens after the campaign has been closed successfully
      await testData.cfManager.connect(testData.alice).claim(aliceAddress);
      //// Jane has to claim tokens after the campaign has been closed successfully
      await testData.cfManager.connect(testData.jane).claim(janeAddress);
      //// Test claim balances. Jane and Alice should each own 100k tokens each ($100k investment each at $1/token)
      expect(await testData.asset.balanceOf(janeAddress)).to.be.equal(
        await ethers.utils.parseEther(janeTotalInvestment.toString())
      );
      expect(await testData.asset.balanceOf(aliceAddress)).to.be.equal(
        await ethers.utils.parseEther(aliceInvestment.toString())
      );

      //// Test sending tokens to the asset owner wallet (janeAdditionalInvestment).
      //// Jane sends half of her tokens (50k out of 100k) back to the asset owner
      await testData.asset.connect(testData.jane).transfer(
          testData.issuerOwner.getAddress(),
          await ethers.utils.parseEther(janeAdditionalInvestment.toString())
      );

      //// After Jane sends back janeAdditionalTokens, Alice owns 100k tokens while Jane is left with 50k of tokens
      const janePostInvestmentTokenBalance = await testData.asset.balanceOf(janeAddress);
      const alicePostInvestmentTokenBalance = await testData.asset.balanceOf(aliceAddress);
      expect(janePostInvestmentTokenBalance).to.be.equal(
          await ethers.utils.parseEther(janeInvestment.toString())
      );
      expect(alicePostInvestmentTokenBalance).to.be.equal(
          await ethers.utils.parseEther(aliceInvestment.toString())
      );
      
      //// Verify tokens can't be transfered
      await expect(
        testData.asset.connect(testData.alice).transfer(janeAddress, 1000)
      ).to.be.reverted;

      //// Mirrored token deployed
      const mirroredAsset = await (await ethers.getContractFactory("MirroredToken", testData.deployer)).deploy(
          `APX-${testData.assetName}`,
          `APX-${testData.assetTicker}`,
          testData.asset.address
      );

      //// Asset is registered on the APX Registry and connected to the mirrored token
      await helpers.registerAsset(
          testData.assetManager, testData.apxRegistry, testData.asset.address, mirroredAsset.address
      );

      //// Jane mirrors her tokens
      const tokensToMirror = ethers.utils.parseEther("50000"); // all of the jane tokens will be mirrored
      await testData.asset.connect(testData.jane).approve(testData.asset.address, tokensToMirror);
      await testData.asset.connect(testData.jane).lockTokens(tokensToMirror);
      const janePostLockAssetBalance = await testData.asset.balanceOf(janeAddress);
      expect(janePostLockAssetBalance).to.be.equal(0);
      const janePostLockMirroredAssetBalance = await mirroredAsset.balanceOf(janeAddress);
      expect(janePostLockMirroredAssetBalance).to.be.equal(tokensToMirror);
      const mirroredTokenSupply = await mirroredAsset.totalSupply();
      expect(mirroredTokenSupply).to.be.equal(tokensToMirror);

      ////// update market price for asset
      ////// price: $0.70, expiry: 60 seconds
      await helpers.updatePrice(testData.priceManager, testData.apxRegistry, mirroredAsset, 11000, 60);

      //// Asset owner liquidates asset
      // Asset was crowdfunded at $1/token and is now trading at $1.10/token so the total supply must be liquidated
      // at the max($1, $1.10), therefore must be liquidated at the price of $1.10.
      // Since the asset circulating supply is 150k tokens (jane and alice), liqudiation funds = 150k tokens * $1.10 = $165k
      // Project owner already holds $200k at his wallet after finalizing the campaign so he is good to go.
      // Alice is entitled to (2/3) and Jane to (1/3) of the $165k liquidation amount according to their token holdings.
      const liquidationAmount = 165000;
      const liquidationAmountWei = await helpers.parseStablecoin(liquidationAmount, testData.stablecoin);
      const liquidatorBalanceBeforeLiquidation = await testData.stablecoin.balanceOf(issuerOwnerAddress);
      expect(liquidatorBalanceBeforeLiquidation).to.be.equal(fundsRaisedWei);
      await helpers.liquidate(testData.issuerOwner, testData.asset, testData.stablecoin, liquidationAmount);
      const liquidatorBalanceAfterLiquidation = await testData.stablecoin.balanceOf(issuerOwnerAddress);
      expect(liquidatorBalanceAfterLiquidation).to.be.equal(fundsRaisedWei.sub(liquidationAmountWei));
      const assetTotalSupply = await testData.asset.totalSupply();
      expect(await (testData.asset.balanceOf(issuerOwnerAddress))).to.be.equal(assetTotalSupply);

      //// Alice claims liquidation share
      const aliceLiquidationShare = 110000; // liquidationAmount * (2/3) 
      const aliceLiquidationShareWei = await helpers.parseStablecoin(aliceLiquidationShare, testData.stablecoin);
      await helpers.claimLiquidationShare(testData.alice, testData.asset);
      const aliceBalanceAfterLiquidationClaim = await testData.stablecoin.balanceOf(aliceAddress);
      expect(aliceBalanceAfterLiquidationClaim).to.be.equal(aliceLiquidationShareWei);
      expect(await testData.asset.balanceOf(aliceAddress)).to.be.equal(0);

      //// Jane converts mirrored to original and claims liquidation share
      await mirroredAsset.connect(testData.jane).burnMirrored(tokensToMirror);
      const janeLiquidationShare = 55000;   // liquidationAmount * (1/3)
      const janeLiquidationShareWei = await helpers.parseStablecoin(janeLiquidationShare, testData.stablecoin);
      await helpers.claimLiquidationShare(testData.jane, testData.asset);
      const janeBalanceAfterLiquidationClaim = await testData.stablecoin.balanceOf(janeAddress);
      expect(janeBalanceAfterLiquidationClaim).to.be.equal(janeLiquidationShareWei);
      expect(await testData.asset.balanceOf(janeAddress)).to.be.equal(0);

      //// Fetch crowdfunding campaign state
      const state = await testData.cfManager.getState()
      const stablecoinDecimals = await testData.stablecoin.decimals();
      const expectedTotalTokensSold = await ethers.utils.formatUnits(totalInvestment.toString(), stablecoinDecimals);
      const fetchedTotalTokensSold = await ethers.utils.formatEther(state.totalTokensSold.toString());
      console.log("fetched crowdfunding campaign state", state);
      expect(state.issuer).to.be.equal(testData.issuer.address)
      expect(state.owner).to.be.equal(await testData.issuerOwner.getAddress())
      expect(state.contractAddress).to.be.equal(testData.cfManager.address)
      expect(state.asset).to.be.equal(testData.asset.address)
      expect(state.canceled).to.be.false
      expect(state.finalized).to.be.true
      expect(state.whitelistRequired).to.be.true
      expect(state.info).to.be.equal(testData.campaignInfoHash)
      expect(state.totalFundsRaised, "totalFundsRaised").to.be.equal(totalInvestment.toString())
      expect(fetchedTotalTokensSold, "totalTokensSold").to.be.equal(expectedTotalTokensSold)
      expect(state.tokenPrice, "tokenPrice").to.be.equal(testData.campaignInitialPricePerToken)
      expect(state.minInvestment, "minInvestment").to.be.equal(await helpers.parseStablecoin(testData.campaignMinInvestment, testData.stablecoin))
      expect(state.maxInvestment, "maxInvestment").to.be.equal(await helpers.parseStablecoin(testData.campaignMaxInvestment, testData.stablecoin))
      expect(state.softCap, "softCap").to.be.equal(await helpers.parseStablecoin(testData.campaignSoftCap, testData.stablecoin))
      expect(state.totalInvestorsCount, "totalInvestorsCount").to.be.equal(2)
      expect(state.totalClaimsCount, "totalClaimsCount").to.be.equal(2)
      expect(state.totalClaimableTokens, "totalClaimableTokens").to.be.equal(0)
      expect(state.totalTokensBalance, "totalTokensBalance").to.be.equal(0)

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
      const fetchedCampaignInstancesForIssuer = await helpers.fetchCrowdfundingInstancesForIssuer(testData.cfManagerFactory, CAMPAIGN_TYPE, testData.issuer);
      console.log("fetched campaign instances for issuer", fetchedCampaignInstancesForIssuer);

      //// Fetch all the Crowdfunding Campaign instances for one Asset
      const fetchedCampaignInstancesForAsset =
          await helpers.fetchCrowdfundingInstancesForAsset(testData.cfManagerFactory, CAMPAIGN_TYPE, testData.asset);
      console.log("fetched campaign instances for asset", fetchedCampaignInstancesForAsset);

      //// Fetch Issuer instance by id
      const fetchedIssuerById = await helpers.fetchIssuerStateById(testData.issuerFactory, 0);
      console.log("fetched issuer for id=0", fetchedIssuerById);

      //// Fetch Asset instance by id
      const fetchedAssetById = await helpers.fetchAssetStateById(testData.assetFactory, ASSET_TYPE, 0);
      console.log("fetched asset for id=0", fetchedAssetById);

      //// Fetch Crowdfunding campaign instance by id
      const fetchedCampaignById = await helpers.fetchCampaignStateById(testData.cfManagerFactory, CAMPAIGN_TYPE, 0);
      console.log("fetched campaign for id=0", fetchedCampaignById);

      //// Fetch alice tx history
      const aliceTxHistory = await helpers.fetchTxHistory(
          aliceAddress, testData.issuer, testData.cfManagerFactory, CAMPAIGN_TYPE, testData.assetFactory, ASSET_TYPE
      );
      console.log("Alice tx history", aliceTxHistory);

      //// Fetch jane tx history
      const janeTxHistory = await helpers.fetchTxHistory(
          janeAddress, testData.issuer, testData.cfManagerFactory, CAMPAIGN_TYPE, testData.assetFactory, ASSET_TYPE
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

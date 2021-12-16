// @ts-ignore
import { ethers } from "hardhat";
import { expect } from "chai";
import * as helpers from "../../util/helpers";
import { TestData } from "../TestData";
import { BigNumber, Signer } from "ethers";
import { createCampaign } from "./campaign-deployer";

describe("Covers important tests for all campaign flavors", function () {

  const testData = new TestData()
  let issuerOwner: Signer;
  let issuerOwnerAddress: String;

  before(async function () {
    await testData.deploy()
    await testData.deployIssuer();
    issuerOwner = testData.issuerOwner;
    issuerOwnerAddress = await issuerOwner.getAddress();
  });

  it(`should check for regular campaign:
        - anyone can process someone's investment if the approval exists
        - anyone can invest for someone else
        - i can invest for myself
        - noone can take my approval and process investment as his own
  `, async function () {
    const asset = await helpers.createAsset(
      issuerOwnerAddress,
      testData.issuer,
      "test-asset-1",
      1000000,
      false, true, true,
      "Test Asset",
      "TSTA",
      "ipfs-info-hash",
      testData.assetFactory,
      testData.nameRegistry,
      testData.apxRegistry
    );

    const campaign = await createCampaign(
      issuerOwnerAddress,
      "regular-campaign-successful-1",
      asset,
      1000,             // $1 price per token
      10000000,         // $10 softCap (taken from real example)
      10000000,         // $10 min per user investment
      2000000000,       // $2000 max per user investment
      true, "",
      testData.cfManagerFactory,
      testData.nameRegistry,
      testData.feeManager
    );
    await asset.connect(issuerOwner).transfer(
      campaign.address,
      BigNumber.from("1000000000000000000000") // tranfers 1k tokens for sale (1000 * 10e18)
    );

    /////////// TEST invest(spender, beneficiary) POSSIBLE SCENARIOS ///////////
    const investmentAmount = 100 // $100
    const investmentAmountWei = await helpers.parseStablecoin(investmentAmount, testData.stablecoin);

    //// invest() case 1: A invest for A (spends A's funds - ok)
    const walletA1 = ethers.Wallet.createRandom().connect(ethers.provider);
    const addressA1 = await walletA1.getAddress();
    await testData.issuerOwner.sendTransaction({
      to: addressA1,
      value: ethers.utils.parseEther("0.1")
    });
    await testData.stablecoin.transfer(addressA1, investmentAmountWei);
    await expect(
      helpers.investForBeneficiary(walletA1, walletA1, campaign, testData.stablecoin, investmentAmount)
    ).to.be.revertedWith("CfManagerSoftcap: Wallet not whitelisted.");
    await testData.walletApproverService.connect(testData.walletApprover).approveWallet(testData.issuer.address, addressA1);
    await helpers.investForBeneficiary(walletA1, walletA1, campaign, testData.stablecoin, investmentAmount, walletA1);
    expect(await campaign.investmentAmount(addressA1)).to.be.equal(investmentAmountWei);
    await campaign.connect(walletA1).cancelInvestment();
    expect(await testData.stablecoin.balanceOf(addressA1)).to.be.equal(investmentAmountWei);

    //// invest() case 2: A invests for B (spends B's funds - ok)
    const walletA2 = ethers.Wallet.createRandom().connect(ethers.provider);
    const addressA2 = await walletA2.getAddress();
    await testData.issuerOwner.sendTransaction({
      to: addressA2,
      value: ethers.utils.parseEther("0.1")
    });
    const walletB2 = ethers.Wallet.createRandom().connect(ethers.provider);
    const addressB2 = await walletB2.getAddress();
    await testData.issuerOwner.sendTransaction({
      to: addressB2,
      value: ethers.utils.parseEther("0.1")
    });
    await testData.stablecoin.transfer(addressB2, investmentAmountWei);
    await expect(
      helpers.investForBeneficiary(walletB2, walletB2, campaign, testData.stablecoin, investmentAmount, walletA2)
    ).to.be.revertedWith("CfManagerSoftcap: Wallet not whitelisted.");
    await testData.walletApproverService.connect(testData.walletApprover).approveWallet(testData.issuer.address, addressB2);
    await helpers.investForBeneficiary(walletB2, walletB2, campaign, testData.stablecoin, investmentAmount, walletA2)
    expect(await campaign.investmentAmount(addressB2)).to.be.equal(investmentAmountWei);
    await campaign.connect(walletB2).cancelInvestment();
    expect(await testData.stablecoin.balanceOf(addressB2)).to.be.equal(investmentAmountWei);

    //// invest() case 3: A invests for B (spends A's funds - ok)
    const walletA3 = ethers.Wallet.createRandom().connect(ethers.provider);
    const addressA3 = await walletA3.getAddress();
    await testData.issuerOwner.sendTransaction({
      to: addressA3,
      value: ethers.utils.parseEther("0.1")
    });
    const walletB3 = ethers.Wallet.createRandom().connect(ethers.provider);
    const addressB3 = await walletB3.getAddress();
    await testData.issuerOwner.sendTransaction({
      to: addressB3,
      value: ethers.utils.parseEther("0.1")
    });
    await testData.stablecoin.transfer(addressA3, investmentAmountWei);
    await expect(
      helpers.investForBeneficiary(walletA3, walletB3, campaign, testData.stablecoin, investmentAmount, walletA3)
    ).to.be.revertedWith("CfManagerSoftcap: Wallet not whitelisted.");
    await testData.walletApproverService.connect(testData.walletApprover).approveWallet(testData.issuer.address, addressB3);
    await helpers.investForBeneficiary(walletA3, walletB3, campaign, testData.stablecoin, investmentAmount, walletA3)
    expect(await campaign.investmentAmount(addressB3)).to.be.equal(investmentAmountWei);
    await campaign.connect(walletB3).cancelInvestment();
    expect(await testData.stablecoin.balanceOf(addressB3)).to.be.equal(investmentAmountWei);

    //// invest() case 4: A invests for A (spends B's funds - not ok, should fail)
    const walletA4 = ethers.Wallet.createRandom().connect(ethers.provider);
    const addressA4 = await walletA4.getAddress();
    await testData.issuerOwner.sendTransaction({
      to: addressA4,
      value: ethers.utils.parseEther("0.1")
    });
    const walletB4 = ethers.Wallet.createRandom().connect(ethers.provider);
    const addressB4 = await walletB4.getAddress();
    await testData.issuerOwner.sendTransaction({
      to: addressB4,
      value: ethers.utils.parseEther("0.1")
    });
    await testData.stablecoin.transfer(addressB4, investmentAmountWei);
    await expect(
      helpers.investForBeneficiary(walletB4, walletA4, campaign, testData.stablecoin, investmentAmount, walletA4)
    ).to.be.revertedWith("CfManagerSoftcap: Only spender can decide to book the investment on somone else.")
  });

  it('is possible to close the campaign if 1 wei left to be funded (or such a small amount not representable by the token amount)', async () => {
    /**
    * Configuration:
    *   asset supply: 1M tokens
    *   asset precision: 10 ** 18
    *   asset token amount for sale (wei): 190270270270270270270270
    *   stablecoin precision: 10 ** 6 
    *   soft cap (wei): 2111999997
    *   price per token: 111
    *   min per user investment (wei): 550000000
    *   max per user investment (wei): 2000000000
    * 
    * Two investors participating in following usdc amounts (wei):
    *   investor 1: 552299999
    *   investor 2: 1559699999
    */
    const asset = await helpers.createAsset(
      issuerOwnerAddress,
      testData.issuer,
      "test-asset-2",
      1000000,
      false, true, true,
      "Test Asset",
      "TSTA",
      "ipfs-info-hash",
      testData.assetFactory,
      testData.nameRegistry,
      testData.apxRegistry
    );

    // data taken from real example
    const campaign = await createCampaign(
      issuerOwnerAddress,
      "regular-campaign-successful-2",
      asset,
      111,             // $0.111 price per token
      2111999997,      // ~$2112 softCap (taken from real example)
      550000000,       // $550 min per user investment
      2000000000,      // $2000 max per user investment
      true, "",
      testData.cfManagerFactory,
      testData.nameRegistry,
      testData.feeManager
    );
    await asset.connect(issuerOwner).transfer(campaign.address, BigNumber.from("190270270270270270270270"));

    const frankAddress = await testData.frank.getAddress();
    const frankInvestment = BigNumber.from("552299999");
    await testData.walletApproverService.connect(testData.walletApprover).approveWallet(testData.issuer.address, frankAddress);
    await testData.stablecoin.transfer(frankAddress, frankInvestment);
    await testData.stablecoin.connect(testData.frank).approve(campaign.address, frankInvestment);
    await campaign.connect(testData.frank).invest(frankInvestment);

    const aliceAddress = await testData.alice.getAddress();
    const aliceInvestment = BigNumber.from("1559699999");
    await testData.walletApproverService.connect(testData.walletApprover).approveWallet(testData.issuer.address, aliceAddress);
    await testData.stablecoin.transfer(aliceAddress, aliceInvestment);
    await testData.stablecoin.connect(testData.alice).approve(campaign.address, aliceInvestment);
    await campaign.connect(testData.alice).invest(aliceInvestment);

    const oneWei = BigNumber.from("1");
    const commonState = await campaign.commonState();
    expect(commonState.softCap.sub(commonState.fundsRaised)).to.be.equal(oneWei);

    await testData.stablecoin.transfer(aliceAddress, oneWei);
    await testData.stablecoin.approve(campaign.address, oneWei);
    await expect(
      campaign.connect(testData.alice).invest(oneWei)
    ).to.be.revertedWith("CfManagerSoftcap: Investment amount too low.")

    // Campaign can be closed although funds raised is 1wei lower than the configured softCap | special case
    await campaign.connect(issuerOwner).finalize();
    await campaign.connect(testData.frank).claim(frankAddress);
    await campaign.connect(testData.alice).claim(aliceAddress);

    const postFinalizationCampaignTokenBalance = await asset.balanceOf(campaign.address);
    const postFinalizationCampaignUsdcBalance = await testData.stablecoin.balanceOf(campaign.address);
    expect(postFinalizationCampaignTokenBalance).to.be.equal(0);
    expect(postFinalizationCampaignUsdcBalance).to.be.equal(0);

    const assetTotalSupply = await asset.totalSupply();
    const postFinalizationOwnerTokenBalance = await asset.balanceOf(issuerOwnerAddress);
    const postFinalizationOwnerUsdcBalance = await testData.stablecoin.balanceOf(issuerOwnerAddress);
    expect(postFinalizationOwnerTokenBalance).to.be.equal(assetTotalSupply.sub(commonState.tokensSold));
    expect(postFinalizationOwnerUsdcBalance).to.be.equal(commonState.fundsRaised);

    const postFinalizationFrankTokenBalance = await asset.balanceOf(frankAddress);
    const postFinalizationFrankUsdcBalance = await testData.stablecoin.balanceOf(frankAddress);
    expect(postFinalizationFrankTokenBalance).to.be.equal(await campaign.tokenAmount(frankAddress));
    expect(postFinalizationFrankUsdcBalance).to.be.equal(
      frankInvestment.sub(await campaign.investmentAmount(frankAddress))
    );

    const postFinalizationAliceTokenBalance = await asset.balanceOf(aliceAddress);
    const postFinalizationAliceUsdcBalance = await testData.stablecoin.balanceOf(aliceAddress);
    expect(postFinalizationAliceTokenBalance).to.be.equal(await campaign.tokenAmount(aliceAddress));
    expect(postFinalizationAliceUsdcBalance).to.be.equal(
      aliceInvestment.add(oneWei).sub(await campaign.investmentAmount(aliceAddress))
    );
  })

  it(`is supported by the campaign to execute following:
      - can cancel investments by anyone if the campaign has been cancelled
      - fails to cancel investments by anyone if the campaign is still active`, async () => {

    const asset = await helpers.createAsset(
      issuerOwnerAddress,
      testData.issuer,
      "test-asset-3",
      1000000,
      false, true, true,
      "Test Asset",
      "TSTA",
      "ipfs-info-hash",
      testData.assetFactory,
      testData.nameRegistry,
      testData.apxRegistry
    );

    const campaign = await createCampaign(
      issuerOwnerAddress,
      "failed-campaign",
      asset,
      1000,             // $1 price per token
      10000000,         // $10 softCap (taken from real example)
      10000000,         // $10 min per user investment
      2000000000,       // $2000 max per user investment
      true, "",
      testData.cfManagerFactory,
      testData.nameRegistry,
      testData.feeManager
    );
    await asset.connect(issuerOwner).transfer(
      campaign.address,
      BigNumber.from("1000000000000000000000") // tranfers 1k tokens for sale (1000 * 10e18)
    );

    const frankAddress = await testData.frank.getAddress();
    const frankInvestment = await helpers.parseStablecoin("100", testData.stablecoin);
    await testData.stablecoin.transfer(frankAddress, frankInvestment);
    await testData.walletApproverService.connect(testData.walletApprover).approveWallet(testData.issuer.address, frankAddress);

    // Frank invests
    await testData.stablecoin.connect(testData.frank).approve(campaign.address, frankInvestment);
    await campaign.connect(testData.frank).invest(frankInvestment);
    expect(
      await campaign.investmentAmount(frankAddress)
    ).to.be.equal(frankInvestment);

    // Alice can't cancel investment for Frank (campaign is still ongoing)
    await expect(
      campaign.connect(testData.alice).cancelInvestmentFor(frankAddress)
    ).to.be.revertedWith("CfManagerSoftcapVesting: Can only cancel for somoneone if the campaign has been canceled.");

    // Frank can cancel investment by himself though
    await campaign.connect(testData.frank).cancelInvestment();
    expect(
      await campaign.investmentAmount(frankAddress)
    ).to.be.equal(0);

    // Frank invests again
    await testData.stablecoin.connect(testData.frank).approve(campaign.address, frankInvestment);
    await campaign.connect(testData.frank).invest(frankInvestment);
    expect(
      await campaign.investmentAmount(frankAddress)
    ).to.be.equal(frankInvestment);

    // Project owner cancels the campaign
    await campaign.connect(issuerOwner).cancelCampaign();

    // Alice can now cancel investment for Frank
    await campaign.connect(testData.alice).cancelInvestmentFor(frankAddress);
    expect(
      await campaign.investmentAmount(frankAddress)
    ).to.be.equal(0);
    expect(
      await testData.stablecoin.balanceOf(campaign.address)
    ).to.be.equal(0);
    expect(
      await asset.balanceOf(campaign.address)
    ).to.be.equal(0);
    expect(
      await testData.stablecoin.balanceOf(frankAddress)
    ).to.be.equal(frankInvestment);
  })

});

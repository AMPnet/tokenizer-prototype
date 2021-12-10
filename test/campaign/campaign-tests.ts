// // @ts-ignore
// import { ethers } from "hardhat";
// import { expect } from "chai";
// import * as helpers from "../../util/helpers";
// import { TestData } from "../TestData";
// import { BigNumber, Contract, Signer } from "ethers";
// import { advanceBlockTime } from "../../util/utils";

// describe("Covers important tests for all campaign flavors", function () {

//   const testData = new TestData()
//   let issuerOwner: Signer;
//   let issuerOwnerAddress: String;
//   let campaign: Contract;
//   let canceledCampaign: Contract;

//   before(async function () {
//     await testData.deploy()
//     await testData.deployIssuerAssetClassicCampaign();
//     issuerOwner = testData.issuerOwner;
//     issuerOwnerAddress = await issuerOwner.getAddress();
//     campaign = testData.cfManager;
//     canceledCampaign = await helpers.createCfManager(
//         issuerOwnerAddress,
//         "canceled-campaign",
//         testData.asset,
//         10000,       // $1 price per token
//         10000,       // $10k softCap
//         1000,        // $1k min per user investment
//         100000,      // $100k max per user investment
//         true, "",
//         testData.cfManagerFactory,
//         testData.nameRegistry
//     );
//   });

//   it.skip(`should check for regular campaign:
//         - can be closed if 1 wei left until softcap
//         - can cancel investments by anyone if the campaign has been cancelled
//         - fails to cancel investments by anyone if the campaign is still active
//         - anyone can process someone's investment if the approval exists
//         - anyone can invest for someone else
//         - i can invest for myself
//         - noone can take my approval and process investment as his own
//   `, async function () {
//       /**
//        * Configuration:
//        *   asset supply: 1M tokens
//        *   asset precision: 10 ** 18
//        *   asset token amount for sale (wei): 190270270270270270270270
//        *   stablecoin precision: 10 ** 6 
//        *   soft cap (wei): 2111999997
//        *   price per token: 111
//        *   min per user investment (wei): 550000000
//        *   max per user investment (wei): 2000000000
//        * 
//        * Two investors participating in following usdc amounts (wei):
//        *   investor 1: 552299999
//        *   investor 2: 1559699997
//        */
      
//       const ASSET_TYPE = "AssetSimple";
//       const CAMPAIGN_TYPE = "CfManagerSoftcap";
//       const issuerOwnerAddress = await testData.issuerOwner.getAddress();
//       const treasuryAddress = await testData.treasury.getAddress();

//       const frankAddress = await testData.frank.getAddress(); 
//       const aliceAddress = await testData.alice.getAddress();
    
//       //// Frank calls approve and investForBeneficiary() by himself

//       //// Alice tries to cancel Frank's investment (should fail since the campaign is active)

//       //// Frank cancels his investment

//       //// Frank calls approve and invest() by himself

//       //// Alice calls approve and Frank tries to process Alice's investment as his own (should fail)

//       //// Frank processes Alice's investment

//       const aliceInvestment = 100000;
//       const aliceInvestmentWei = ethers.utils.parseEther(aliceInvestment.toString());
//       await testData.stablecoin.transfer(frankAddress, aliceInvestmentWei);
//       await testData.walletApproverService.connect(testData.walletApprover)
//           .approveWallet(testData.issuer.address, aliceAddress);

//       //// Frank invests $100k USDC credited to the Alice's wallet.
//       await helpers.investForBeneficiary(
//         testData.frank,
//         testData.alice,
//         testData.cfManagerVesting,
//         testData.stablecoin,
//         aliceInvestment
//       );

//     });

// });
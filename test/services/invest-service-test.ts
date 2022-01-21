// @ts-ignore
import * as helpers from "../../util/helpers";
import {expect} from "chai";
import {describe, it} from "mocha";
import {TestData} from "../TestData";

describe("Invest service test", function () {

    const testData = new TestData();
    const investment = 100000;

    beforeEach(async function () {
        await testData.deploy();
        await testData.deployIssuerAssetClassicCampaign();
    });

    it('should auto invest 2 wallets', async function () {
        //// Alice and Frank buy $100k USDC and goes through kyc process (wallet approved)
        const frankAddress = await testData.frank.getAddress();
        const aliceAddress = await testData.alice.getAddress();
        const investment = 100000;
        const investmentWei = await helpers.parseStablecoin(investment, testData.stablecoin);
        await testData.stablecoin.transfer(frankAddress, investmentWei);
        await testData.stablecoin.transfer(aliceAddress, investmentWei);

        //// Invest service will return empty list of wallets ready for auto invest
        const request = [
            {investor: aliceAddress, campaign: testData.cfManager.address, amount: investmentWei},
            {investor: frankAddress, campaign: testData.cfManager.address, amount: investmentWei}
        ]
        const notApproved = await testData.investService.getStatus(request);
        expect(notApproved.length).to.be.equal(2);
        expect(notApproved[0].readyToInvest).to.be.equal(false);
        expect(notApproved[1].readyToInvest).to.be.equal(false);

        //// Users approve cf manager to spend stablecoin
        await testData.stablecoin.connect(testData.alice).approve(testData.cfManager.address, investmentWei);
        await testData.stablecoin.connect(testData.frank).approve(testData.cfManager.address, investmentWei);

        await testData.walletApproverService.connect(testData.walletApprover)
            .approveWallet(testData.issuer.address, aliceAddress);
        await testData.walletApproverService.connect(testData.walletApprover)
            .approveWallet(testData.issuer.address, frankAddress);

        const approved = await testData.investService.getStatus(request);
        expect(approved.length).to.be.equal(2);
        expect(approved[0].readyToInvest).to.be.equal(true);
        expect(approved[1].readyToInvest).to.be.equal(true);

        await testData.investService.connect(testData.deployer).investFor(request);
        const campaignState = await testData.cfManager.commonState();
        expect(campaignState.fundsRaised).to.be.equal(investmentWei.mul(2));
    });

    it('should not fail if one wallet is not ready to invest', async function () {
        //// Alice and Frank buy $100k USDC and goes through kyc process (wallet approved)
        const frankAddress = await testData.frank.getAddress();
        const aliceAddress = await testData.alice.getAddress();
        const investment = 100000;
        const investmentWei = await helpers.parseStablecoin(investment, testData.stablecoin);
        await testData.stablecoin.transfer(frankAddress, investmentWei);
        await testData.stablecoin.transfer(aliceAddress, investmentWei);
        await testData.walletApproverService.connect(testData.walletApprover)
            .approveWallet(testData.issuer.address, aliceAddress);
        await testData.walletApproverService.connect(testData.walletApprover)
            .approveWallet(testData.issuer.address, frankAddress);

        //// Invest service will return empty list of wallets ready for auto invest
        const request = [
            {investor: aliceAddress, campaign: testData.cfManager.address, amount: investmentWei},
            {investor: frankAddress, campaign: testData.cfManager.address, amount: investmentWei}
        ]
        const notApproved = await testData.investService.getStatus(request);
        expect(notApproved.length).to.be.equal(2);
        expect(notApproved[0].readyToInvest).to.be.equal(false);
        expect(notApproved[1].readyToInvest).to.be.equal(false);

        //// Users approve cf manager to spend stablecoin
        await testData.stablecoin.connect(testData.alice).approve(testData.cfManager.address, investmentWei);
        await testData.stablecoin.connect(testData.frank).approve(testData.cfManager.address, investmentWei);

        const approved = await testData.investService.getStatus(request);
        expect(approved.length).to.be.equal(2);
        expect(approved[0].readyToInvest).to.be.equal(true);
        expect(approved[1].readyToInvest).to.be.equal(true);

        //// Suspend one wallet to fail investment transaction
        await testData.walletApproverService.connect(testData.walletApprover)
            .suspendWallet(testData.issuer.address, frankAddress);

        await testData.investService.connect(testData.deployer).investFor(approved);
        const campaignState = await testData.cfManager.commonState();
        expect(campaignState.fundsRaised).to.be.equal(investmentWei);
    });

    it('should return correct ready to invest value for all cases', async function () {
        const aliceAddress = await testData.alice.getAddress();
        const investmentWei = await helpers.parseStablecoin(investment, testData.stablecoin);

        await verifyWalletReadyToInvest(aliceAddress, false);
        await testData.stablecoin.transfer(aliceAddress, investmentWei);
        await verifyWalletReadyToInvest(aliceAddress, false);

        await testData.walletApproverService.connect(testData.walletApprover)
            .approveWallet(testData.issuer.address, aliceAddress);
        await verifyWalletReadyToInvest(aliceAddress, false);

        await testData.stablecoin.connect(testData.alice).approve(testData.cfManager.address, investmentWei);
        await verifyWalletReadyToInvest(aliceAddress, true);

        const pending = await testData.investService.getPendingFor(
            aliceAddress,
            testData.issuer.address,
            [testData.cfManagerFactory.address, testData.cfManagerVestingFactory.address],
            testData.queryService.address,
            testData.nameRegistry.address
        );
        expect(pending.length).to.be.equal(1);
        const firstPending = pending[0];
        expect(firstPending.investor).to.be.equal(aliceAddress);
        expect(firstPending.campaign).to.be.equal(testData.cfManager.address);
        expect(firstPending.allowance).to.be.equal(investmentWei);
        expect(firstPending.balance).to.be.equal(investmentWei);
        expect(firstPending.alreadyInvested).to.be.equal(0);
        expect(firstPending.kycPassed).to.be.equal(true);
    });

    it('should auto invest for balance below allowance', async function () {
        //// Frank buy $100k USDC and goes through kyc process (wallet approved)
        const frankAddress = await testData.frank.getAddress();
        const investment = 100;
        const investmentWei = await helpers.parseStablecoin(investment, testData.stablecoin);
        await testData.stablecoin.transfer(frankAddress, investmentWei);
        await testData.walletApproverService.connect(testData.walletApprover)
            .approveWallet(testData.issuer.address, frankAddress);

        //// Users approve cf manager to spend stablecoin
        const allowanceWei = await helpers.parseStablecoin(1000000000, testData.stablecoin);
        await testData.stablecoin.connect(testData.frank).approve(testData.cfManager.address, allowanceWei);

        //// Invest service will return wallet that has passed kyc with maximum user investment
        const request = [
            {investor: frankAddress, campaign: testData.cfManager.address, amount: allowanceWei}
        ]
        const approved1 = await testData.investService.getStatus(request);
        expect(approved1.length).to.be.equal(1);
        expect(approved1[0].readyToInvest).to.be.equal(true);
        expect(approved1[0].amount).to.be.equal(investmentWei);

        //// User deposits min investment
        const minInvestment = await helpers.parseStablecoin(100000, testData.stablecoin);
        await testData.stablecoin.transfer(frankAddress, minInvestment);
        const maxUserInvestment = investmentWei.add(minInvestment)

        //// Invest service will return wallet that has passed kyc with updated maximum user investment
        const approved2 = await testData.investService.getStatus(request);
        expect(approved2.length).to.be.equal(1);
        expect(approved2[0].readyToInvest).to.be.equal(true);
        expect(approved2[0].amount).to.be.equal(maxUserInvestment);

        //// Use list of approved wallets for auto invest because this will return user max investment
        await testData.investService.connect(testData.deployer).investFor(approved2);
        const campaignState = await testData.cfManager.commonState();
        expect(campaignState.fundsRaised).to.be.equal(maxUserInvestment);
    });

    async function verifyWalletReadyToInvest(wallet: string, ready: boolean) {
        const request = [
            {investor: wallet, campaign: testData.cfManager.address, amount: investment}
        ]
        const walletStates = await testData.investService.getStatus(request);
        console.log(walletStates);
        expect(walletStates.length).to.be.equal(1);
        expect(walletStates[0].readyToInvest).to.be.equal(ready);
    }
})

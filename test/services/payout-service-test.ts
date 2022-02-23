// @ts-ignore
import * as helpers from "../../util/helpers";
import { expect } from "chai";
import { describe, it } from "mocha";
import { TestData } from "../TestData";
import { ethers, Contract, BigNumber } from "ethers";

describe("Payout service tests", function () {

    const testData = new TestData();

    before(async function() {
        await testData.deploy();
        await testData.deployIssuer();
    });

    it(`must return 0 payouts if issuer contains no payouts for assets`, async function () {
        const payouts = await testData.payoutService.getPayoutsForIssuer(
            testData.issuer.address,
            testData.payoutManager.address,
            [
                testData.assetFactory.address,
                testData.assetTransferableFactory.address,
                testData.assetSimpleFactory.address
            ]
        )
        expect(payouts.length).to.be.equal(0);
    });

    it(`must check for: 
            - payouts for all three asset types returned by the payout service for issuer
            - payout states for given payoutIds and investor for all three asset types`, async function () {
        const issuerOwnerAddress = await testData.issuerOwner.getAddress();
        const supply = 100000;

        const assetBasic: Contract = await helpers.createAsset(
            issuerOwnerAddress,
            testData.issuer,
            "asset-basic",
            supply,
            true, true, true,
            "asset-basic", "AB", "cid",
            testData.assetFactory,
            testData.nameRegistry,
            testData.apxRegistry
        );
        const assetTransferable = await helpers.createAssetTransferable(
            issuerOwnerAddress,
            testData.issuer,
            "asset-transferable",
            supply,
            true, true,
            "asset-transferable", "AT", "cid",
            testData.assetTransferableFactory,
            testData.nameRegistry,
            testData.apxRegistry
        );
        const assetSimple = await helpers.createAssetSimple(
            issuerOwnerAddress,
            testData.issuer,
            "asset-simple",
            supply,
            "asset-simple",
            "AS", "cid",
            testData.assetSimpleFactory,
            testData.nameRegistry
        );
        const payoutsBeforeCreation = await testData.payoutService.getPayoutsForIssuer(
            testData.issuer.address,
            testData.payoutManager.address,
            [
                testData.assetFactory.address,
                testData.assetSimpleFactory.address,
                testData.assetTransferableFactory.address
            ]
        );
        expect(payoutsBeforeCreation.length).to.be.equal(0);

        const rewardAmount = ethers.utils.parseUnits("100", 6);
        const merkleRoot = "0xccd102c8ad222de27fa4463a41bcae172e4d4b0eddeeaa4dafe4bb979aa68c3c";
        const merkleDepth = BigNumber.from(3);
        const merkleIpfsHash = "merkle-ipfs-hash";
        const blockNumber = BigNumber.from(123);
        const payoutInfo: PayoutInfo = {
            totalAssetAmount: ethers.utils.parseEther(supply.toString()),
            ignoredAssetAddresses: [],
            payoutInfo: "cid",
            assetSnapshotMerkleRoot: merkleRoot,
            assetSnapshotMerkleDepth: merkleDepth,
            assetSnapshotBlockNumber: blockNumber,
            assetSnapshotMerkleIpfsHash: merkleIpfsHash,
            totalRewardAmount: rewardAmount,
            rewardAsset: testData.stablecoin.address
        };

        await testData.stablecoin.connect(testData.deployer).transfer(issuerOwnerAddress, rewardAmount.mul(3));
        await testData.stablecoin.connect(testData.issuerOwner).approve(
            testData.payoutManager.address,
            rewardAmount.mul(3)
        );

        const expectedAssetSimplePayoutId = 0;
        await testData.payoutManager.connect(testData.issuerOwner).createPayout({
            asset: assetSimple.address,
            totalAssetAmount: payoutInfo.totalAssetAmount,
            ignoredAssetAddresses: payoutInfo.ignoredAssetAddresses,
            payoutInfo: payoutInfo.payoutInfo,
            assetSnapshotMerkleRoot: payoutInfo.assetSnapshotMerkleRoot,
            assetSnapshotMerkleDepth: payoutInfo.assetSnapshotMerkleDepth,
            assetSnapshotBlockNumber: payoutInfo.assetSnapshotBlockNumber,
            assetSnapshotMerkleIpfsHash: payoutInfo.assetSnapshotMerkleIpfsHash,
            rewardAsset: payoutInfo.rewardAsset,
            totalRewardAmount: payoutInfo.totalRewardAmount
        });

        const expectedAssetTransferablePayoutId = 1;
        await testData.payoutManager.connect(testData.issuerOwner).createPayout({
            asset: assetTransferable.address,
            totalAssetAmount: payoutInfo.totalAssetAmount,
            ignoredAssetAddresses: payoutInfo.ignoredAssetAddresses,
            payoutInfo: payoutInfo.payoutInfo,
            assetSnapshotMerkleRoot: payoutInfo.assetSnapshotMerkleRoot,
            assetSnapshotMerkleDepth: payoutInfo.assetSnapshotMerkleDepth,
            assetSnapshotBlockNumber: payoutInfo.assetSnapshotBlockNumber,
            assetSnapshotMerkleIpfsHash: payoutInfo.assetSnapshotMerkleIpfsHash,
            rewardAsset: payoutInfo.rewardAsset,
            totalRewardAmount: payoutInfo.totalRewardAmount
        });

        const expectedAssetBasicPayoutId = 2;
        await testData.payoutManager.connect(testData.issuerOwner).createPayout({
            asset: assetBasic.address,
            totalAssetAmount: payoutInfo.totalAssetAmount,
            ignoredAssetAddresses: payoutInfo.ignoredAssetAddresses,
            payoutInfo: payoutInfo.payoutInfo,
            assetSnapshotMerkleRoot: payoutInfo.assetSnapshotMerkleRoot,
            assetSnapshotMerkleDepth: payoutInfo.assetSnapshotMerkleDepth,
            assetSnapshotBlockNumber: payoutInfo.assetSnapshotBlockNumber,
            assetSnapshotMerkleIpfsHash: payoutInfo.assetSnapshotMerkleIpfsHash,
            rewardAsset: payoutInfo.rewardAsset,
            totalRewardAmount: payoutInfo.totalRewardAmount
        });

        const payoutsAfterCreation = await testData.payoutService.getPayoutsForIssuer(
            testData.issuer.address,
            testData.payoutManager.address,
            [
                testData.assetFactory.address,
                testData.assetTransferableFactory.address,
                testData.assetSimpleFactory.address
            ]
        );

        expect(payoutsAfterCreation.length).to.be.equal(3);
        
        const assetBasicPayout: PayoutForIssuerItem = 
            payoutsAfterCreation.find(item => item.asset == assetBasic.address);
        const assetTransferablePayout: PayoutForIssuerItem = 
            payoutsAfterCreation.find(item => item.asset == assetTransferable.address);
        const assetSimplePayout: PayoutForIssuerItem = 
            payoutsAfterCreation.find(item => item.asset == assetSimple.address);
        
        assertPayoutForIssuerResponse(
            expectedAssetSimplePayoutId,
            assetSimple.address,
            issuerOwnerAddress,
            payoutInfo,
            assetSimplePayout
        );
        assertPayoutForIssuerResponse(
            expectedAssetTransferablePayoutId,
            assetTransferable.address,
            issuerOwnerAddress,
            payoutInfo,
            assetTransferablePayout
        );
        assertPayoutForIssuerResponse(
            expectedAssetBasicPayoutId,
            assetBasic.address,
            issuerOwnerAddress,
            payoutInfo,
            assetBasicPayout
        );

        const aliceAddress = await testData.alice.getAddress();
        const payoutStatesForInvestor = await testData.payoutService.getPayoutStatesForInvestor(
            aliceAddress,
            testData.payoutManager.address,
            [ BigNumber.from(0), BigNumber.from(1), BigNumber.from(2) ]
        );
        expect(payoutStatesForInvestor.length).to.be.equal(3);
        expect(payoutStatesForInvestor[0].payoutId).to.be.equal(0);
        expect(payoutStatesForInvestor[0].investor).to.be.equal(aliceAddress);
        expect(payoutStatesForInvestor[0].amountClaimed).to.be.equal(0);
        expect(payoutStatesForInvestor[1].payoutId).to.be.equal(1);
        expect(payoutStatesForInvestor[1].investor).to.be.equal(aliceAddress);
        expect(payoutStatesForInvestor[1].amountClaimed).to.be.equal(0);
        expect(payoutStatesForInvestor[2].payoutId).to.be.equal(2);
        expect(payoutStatesForInvestor[2].investor).to.be.equal(aliceAddress);
        expect(payoutStatesForInvestor[2].amountClaimed).to.be.equal(0);
    });

    /* HELPERS */

    interface PayoutInfo {
        totalAssetAmount: BigNumber,
        ignoredAssetAddresses: string[],
        payoutInfo: string,
        assetSnapshotMerkleRoot: string,
        assetSnapshotMerkleDepth: BigNumber,
        assetSnapshotBlockNumber: BigNumber,
        assetSnapshotMerkleIpfsHash: string,
        totalRewardAmount: BigNumber,
        rewardAsset: string
    };

    interface PayoutForIssuerItem {
        payoutId: BigNumber;
        payoutOwner: string;
        payoutInfo: string;
        isCanceled: boolean;
        asset: string;
        totalAssetAmount: BigNumber;
        ignoredAssetAddresses: string[];
        assetSnapshotMerkleRoot: string;
        assetSnapshotMerkleDepth: BigNumber;
        assetSnapshotBlockNumber: BigNumber;
        assetSnapshotMerkleIpfsHash: string;
        rewardAsset: string;
        totalRewardAmount: BigNumber;
        remainingRewardAmount: BigNumber;
    }

    function assertPayoutForIssuerResponse(
        expectedPayoutId: number, 
        expectedAsset: string,
        expectedPayoutOwner: string,
        expectedPayoutInfo: PayoutInfo,
        fetchedPayoutForIssuerItem: PayoutForIssuerItem
    ) {
        expect(fetchedPayoutForIssuerItem.payoutId).to.be.equal(expectedPayoutId);
        expect(fetchedPayoutForIssuerItem.asset).to.be.equal(expectedAsset);
        expect(fetchedPayoutForIssuerItem.payoutOwner).to.be.equal(expectedPayoutOwner);
        expect(fetchedPayoutForIssuerItem.payoutInfo).to.be.equal(expectedPayoutInfo.payoutInfo);
        expect(fetchedPayoutForIssuerItem.isCanceled).to.be.false;
        expect(fetchedPayoutForIssuerItem.totalAssetAmount).to.be.equal(expectedPayoutInfo.totalAssetAmount);
        expect(fetchedPayoutForIssuerItem.ignoredAssetAddresses.length).to.be.equal(0);
        expect(fetchedPayoutForIssuerItem.assetSnapshotMerkleRoot).to.be.equal(expectedPayoutInfo.assetSnapshotMerkleRoot);
        expect(fetchedPayoutForIssuerItem.assetSnapshotMerkleDepth).to.be.equal(expectedPayoutInfo.assetSnapshotMerkleDepth);
        expect(fetchedPayoutForIssuerItem.assetSnapshotBlockNumber).to.be.equal(expectedPayoutInfo.assetSnapshotBlockNumber);
        expect(fetchedPayoutForIssuerItem.assetSnapshotMerkleIpfsHash).to.be.equal(expectedPayoutInfo.assetSnapshotMerkleIpfsHash);
        expect(fetchedPayoutForIssuerItem.rewardAsset).to.be.equal(expectedPayoutInfo.rewardAsset);
        expect(fetchedPayoutForIssuerItem.totalRewardAmount).to.be.equal(expectedPayoutInfo.totalRewardAmount);
        expect(fetchedPayoutForIssuerItem.remainingRewardAmount).to.be.equal(expectedPayoutInfo.totalRewardAmount);
    }

})

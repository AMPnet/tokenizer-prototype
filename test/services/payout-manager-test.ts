// @ts-ignore
import { ethers } from "hardhat";
import { BigNumber, ContractTransaction, Signer } from "ethers";
import { expect } from "chai";
import { describe, it } from "mocha";
import { IERC20, MerkleTreePathValidator, PayoutManager } from "../../typechain";
import * as helpers from "../../util/helpers";

describe("Payout Manager test", function () {

    //////// CONTRACTS ////////
    let merkleTreePathValidatorService: MerkleTreePathValidator;
    let payoutManager: PayoutManager;
    let asset1: IERC20;
    let asset2: IERC20;
    let rewardAsset: IERC20;

    //////// SIGNERS ////////
    let assetDistributor: Signer;
    let payoutOwner1: Signer;
    let payoutOwner2: Signer;
    let payoutOwner3: Signer;
    let alice: Signer;

    //////// CONST ////////

    // Merkle tree with root hash 0xccd102c8ad222de27fa4463a41bcae172e4d4b0eddeeaa4dafe4bb979aa68c3c
    // was generated for the following holders and balances:
    const holders = [
        "0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266",
        "0x70997970C51812dc3A010C7d01b50e0d17dc79C8",
        "0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC",
        "0x90F79bf6EB2c4f870365E785982E1f101E93b906",
        "0x15d34AAf54267DB7D7c367839AAf71A00a2C6A65",
        "0x9965507D1a55bcC2695C58ba16FB37d819B0A4dc",
        "0x976EA74026E726554dB657fA54763abd0C3a0aa9"
    ];
    const balances = [1000, 2000, 3000, 4000, 5000, 6000, 7000];
    const proofs = [
        [
            "0x1fbd400bd5326802cf3e4f204a758a6262b480feb5d24a2331efb1eb1fa5f6e6",
            "0xc98149b58dee7d807e76dff466baae8fd6652144e979ac2fc82d9fa32e68dd3f",
            "0xd093f9d1eb3721e212189fe2d6691ba0e865c94e58ef25465c4cc3ef8e601094"
        ],
        [
            "0x0e7e48f58c5bd144faf53a9046591ec912af78cd6d8f0c1d8a41ab519e9b596f",
            "0x199ff36af77bbf4cf05c103265a5f946009431a4abbb28f57054c6ab8e657d07",
            "0xd093f9d1eb3721e212189fe2d6691ba0e865c94e58ef25465c4cc3ef8e601094"
        ],
        [
            "0x5c4d5593904ecd1b7d9f868c57a384abd2cd75be094339ad8ab095a226212b55",
            "0xc98149b58dee7d807e76dff466baae8fd6652144e979ac2fc82d9fa32e68dd3f",
            "0xd093f9d1eb3721e212189fe2d6691ba0e865c94e58ef25465c4cc3ef8e601094"
        ],
        [
            "0xb579f5c13eeb27b66f36ee9352993cf06592fae6d57ddaab8173b514d816bca6",
            "0x3fd3cc771a0dac8e044f8d6369b1e5317b29e38905d84690310338c7a8b92b46",
            "0x8cc9d677e018a88d1759c1e895897d137102bed87a8ef5ab7f68bfb3a5054d98"
        ],
        [
            "0x17eded8ad02538d86cb3968c49f57bf8f6610522689115d97799542e598a1de6",
            "0x199ff36af77bbf4cf05c103265a5f946009431a4abbb28f57054c6ab8e657d07",
            "0xd093f9d1eb3721e212189fe2d6691ba0e865c94e58ef25465c4cc3ef8e601094"
        ],
        [
            "0x752e282b9447f0caa9c85222d24f2cbfe6cf08d277349cca7a7ba42cfaac0c2f",
            "0x3fd3cc771a0dac8e044f8d6369b1e5317b29e38905d84690310338c7a8b92b46",
            "0x8cc9d677e018a88d1759c1e895897d137102bed87a8ef5ab7f68bfb3a5054d98"
        ],
        [
            "0x0000000000000000000000000000000000000000000000000000000000000000",
            "0xac2379705bc597ab9d341a458f5bac996d71c3d06a0a3dccdfc84f3ceebf7a4a",
            "0x8cc9d677e018a88d1759c1e895897d137102bed87a8ef5ab7f68bfb3a5054d98"
        ]
    ];
    const merkleRoot = "0xccd102c8ad222de27fa4463a41bcae172e4d4b0eddeeaa4dafe4bb979aa68c3c";
    const merkleDepth = 3;
    const ipfsHash = "test-ipfs-hash";
    const blockNumber = 123;
    const totalAssetAmount = 1000 + 2000 + 3000 + 4000 + 5000 + 6000 + 7000;
    const oneToOneReward = totalAssetAmount;
    const twoToOneReward = totalAssetAmount * 2;
    const ignoredAddresses = [];

    interface Payout {
        id: number;
        owner: string;
        canceled: boolean;
        asset: string;
        totalReward: number;
        remainingReward: number;
    }

    interface PayoutInfo {
        payoutId: BigNumber;
        payoutOwner: string;
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

    function preparePayout(owner: Signer, payout: Payout): Promise<ContractTransaction> {
        return payoutManager.connect(owner).createPayout(
            payout.asset,
            totalAssetAmount,
            ignoredAddresses,
            merkleRoot,
            merkleDepth,
            blockNumber,
            ipfsHash,
            rewardAsset.address,
            payout.totalReward
        );
    }

    async function verifyCreatePayoutEvent(createPayout: Promise<ContractTransaction>, expected: Payout) {
        await expect(createPayout).to.emit(payoutManager, "PayoutCreated").withArgs(
            expected.id,
            expected.owner,
            expected.asset,
            rewardAsset.address,
            expected.totalReward
        );
    }

    function verifyPayoutInfo(payoutInfo: PayoutInfo, expected: Payout) {
        expect(payoutInfo.payoutId).to.be.equal(expected.id);
        expect(payoutInfo.payoutOwner).to.be.equal(expected.owner);
        expect(payoutInfo.isCanceled).to.be.equal(expected.canceled);
        expect(payoutInfo.asset).to.be.equal(expected.asset);
        expect(payoutInfo.totalAssetAmount).to.be.equal(totalAssetAmount);
        expect(payoutInfo.ignoredAssetAddresses).to.have.members(ignoredAddresses);
        expect(payoutInfo.assetSnapshotMerkleRoot).to.be.equal(merkleRoot);
        expect(payoutInfo.assetSnapshotMerkleDepth).to.be.equal(merkleDepth);
        expect(payoutInfo.assetSnapshotBlockNumber).to.be.equal(blockNumber);
        expect(payoutInfo.assetSnapshotMerkleIpfsHash).to.be.equal(ipfsHash);
        expect(payoutInfo.rewardAsset).to.be.equal(rewardAsset.address);
        expect(payoutInfo.totalRewardAmount).to.be.equal(expected.totalReward);
        expect(payoutInfo.remainingRewardAmount).to.be.equal(expected.remainingReward);
    }

    beforeEach(async function () {
        const accounts: Signer[] = await ethers.getSigners();

        // addresses [0-6] are used in the Merkle tree
        assetDistributor = accounts[7];
        payoutOwner1     = accounts[8];
        payoutOwner2     = accounts[9];
        payoutOwner3     = accounts[10];
        alice            = accounts[11];

        const merkleTreeValidatorFactory = await ethers.getContractFactory("MerkleTreePathValidator", assetDistributor);
        const merkleTreeValidatorContract = await merkleTreeValidatorFactory.deploy();

        merkleTreePathValidatorService = merkleTreeValidatorContract as MerkleTreePathValidator;

        const payoutManagerFactory = await ethers.getContractFactory("PayoutManager", assetDistributor);
        const payoutManagerContract = await payoutManagerFactory.deploy(merkleTreePathValidatorService.address);

        payoutManager = payoutManagerContract as PayoutManager;

        asset1 = (await helpers.deployStablecoin(assetDistributor, "1000000000000000000", 10)) as IERC20;
        asset2 = (await helpers.deployStablecoin(assetDistributor, "1000000000000", 4)) as IERC20;
        rewardAsset = (await helpers.deployStablecoin(assetDistributor, "1000000000000", 6)) as IERC20;
    });

    it('should not allow creation of payout without asset holders', async function() {
        const createPayout = payoutManager.connect(payoutOwner1).createPayout(
            asset1.address,
            0, // total asset amount
            ignoredAddresses,
            merkleRoot,
            merkleDepth,
            blockNumber,
            ipfsHash,
            rewardAsset.address,
            oneToOneReward
        );

        await expect(createPayout).to.be.revertedWith("PayoutManager: cannot create payout without holders");
    });

    it('should not allow creation of payout without reward', async function() {
        const createPayout = payoutManager.connect(payoutOwner1).createPayout(
            asset1.address,
            totalAssetAmount,
            ignoredAddresses,
            merkleRoot,
            merkleDepth,
            blockNumber,
            ipfsHash,
            rewardAsset.address,
            0 // total reward amount
        );

        await expect(createPayout).to.be.revertedWith("PayoutManager: cannot create payout without reward");
    });

    it('should not allow creation of payout with zero-depth Merkle tree', async function() {
        const createPayout = payoutManager.connect(payoutOwner1).createPayout(
            asset1.address,
            totalAssetAmount,
            ignoredAddresses,
            merkleRoot,
            0, // Merkle depth
            blockNumber,
            ipfsHash,
            rewardAsset.address,
            oneToOneReward
        );

        await expect(createPayout).to.be.revertedWith("PayoutManager: Merkle tree depth cannot be zero");
    });

    it('should not allow creation of payout with insufficient approved reward asset amount', async function() {
        const createPayout = payoutManager.connect(payoutOwner1).createPayout(
            asset1.address,
            totalAssetAmount,
            ignoredAddresses,
            merkleRoot,
            merkleDepth,
            blockNumber,
            ipfsHash,
            rewardAsset.address,
            oneToOneReward
        );

        await expect(createPayout).to.be.revertedWith("PayoutManager: insufficient reward asset allowance");
    });

    it('should create single payout and claim rewards', async function() {
        const ownerAddress = await payoutOwner1.getAddress();

        // transfer reward token to payoutOwner1
        await rewardAsset.connect(assetDistributor).transfer(ownerAddress, oneToOneReward);

        // payoutOwner1 approves reward for payout
        await rewardAsset.connect(payoutOwner1).approve(payoutManager.address, oneToOneReward);

        const payout: Payout = {
            id: 0,
            owner: ownerAddress,
            canceled: false,
            asset: asset1.address,
            totalReward: oneToOneReward,
            remainingReward: oneToOneReward
        }

        // payoutOwner1 creates payout for asset1
        const createPayout = preparePayout(payoutOwner1, payout);

        // verify PayoutCreated event data
        await verifyCreatePayoutEvent(createPayout, payout);

        // verify payout info by ID
        const payoutInfo = await payoutManager.getPayoutInfo(payout.id);
        verifyPayoutInfo(payoutInfo, payout);

        // verify payout info per asset
        const assetPayouts = await payoutManager.getPayoutsForAsset(asset1.address);
        expect(assetPayouts.length).to.be.equal(1);
        verifyPayoutInfo(assetPayouts[0], payout);

        // claim rewards for all accounts in the payout
        for (let i = 0; i < holders.length; i++) {
            await payoutManager.connect(alice).claim(payout.id, holders[i], balances[i], proofs[i]);
        }
        
        // verify claimed rewards
        for (let i = 0; i < holders.length; i++) {
            const balance = await rewardAsset.balanceOf(holders[i]);
            expect(balance).to.be.equal(balances[i]);
        }

        // verify remaining reward amount is now zero
        const afterPayoutInfo = await payoutManager.getPayoutInfo(payout.id);
        verifyPayoutInfo(afterPayoutInfo, {...payout, remainingReward: 0});
    });

    it('should create multiple payouts and claim rewards', async function() {
        const ownerAddress1 = await payoutOwner1.getAddress();
        const ownerAddress2 = await payoutOwner2.getAddress();
        const ownerAddress3 = await payoutOwner3.getAddress();

        // transfer reward token to payoutOwners
        await rewardAsset.connect(assetDistributor).transfer(ownerAddress1, oneToOneReward * 3); // one payout with 1:1 and one with 2:1
        await rewardAsset.connect(assetDistributor).transfer(ownerAddress2, oneToOneReward);
        await rewardAsset.connect(assetDistributor).transfer(ownerAddress3, oneToOneReward);

        // payoutOwners approve rewards for payouts
        await rewardAsset.connect(payoutOwner1).approve(payoutManager.address, oneToOneReward * 3);
        await rewardAsset.connect(payoutOwner2).approve(payoutManager.address, oneToOneReward);
        await rewardAsset.connect(payoutOwner3).approve(payoutManager.address, oneToOneReward);

        const payout1: Payout = {
            id: 0,
            owner: ownerAddress1,
            canceled: false,
            asset: asset1.address,
            totalReward: oneToOneReward,
            remainingReward: oneToOneReward
        }
        const payout2: Payout = {
            id: 1,
            owner: ownerAddress1,
            canceled: false,
            asset: asset2.address,
            totalReward: twoToOneReward,
            remainingReward: twoToOneReward
        }
        const payout3: Payout = {
            id: 2,
            owner: ownerAddress2,
            canceled: false,
            asset: asset1.address,
            totalReward: oneToOneReward,
            remainingReward: oneToOneReward
        }
        const payout4: Payout = {
            id: 3,
            owner: ownerAddress3,
            canceled: false,
            asset: asset2.address,
            totalReward: oneToOneReward,
            remainingReward: oneToOneReward
        }

        // payoutOwners create payouts for assets
        const createPayout1 = preparePayout(payoutOwner1, payout1);
        const createPayout2 = preparePayout(payoutOwner1, payout2);
        const createPayout3 = preparePayout(payoutOwner2, payout3);
        const createPayout4 = preparePayout(payoutOwner3, payout4);

        // verify PayoutCreated event data
        await verifyCreatePayoutEvent(createPayout1, payout1);
        await verifyCreatePayoutEvent(createPayout2, payout2);
        await verifyCreatePayoutEvent(createPayout3, payout3);
        await verifyCreatePayoutEvent(createPayout4, payout4);

        // verify payout infos by IDs
        const payoutInfo1 = await payoutManager.getPayoutInfo(payout1.id);
        verifyPayoutInfo(payoutInfo1, payout1);

        const payoutInfo2 = await payoutManager.getPayoutInfo(payout2.id);
        verifyPayoutInfo(payoutInfo2, payout2);

        const payoutInfo3 = await payoutManager.getPayoutInfo(payout3.id);
        verifyPayoutInfo(payoutInfo3, payout3);

        const payoutInfo4 = await payoutManager.getPayoutInfo(payout4.id);
        verifyPayoutInfo(payoutInfo4, payout4);

        // verify payout infos per asset
        const asset1Payouts = await payoutManager.getPayoutsForAsset(asset1.address);
        expect(asset1Payouts.length).to.be.equal(2);
        verifyPayoutInfo(asset1Payouts[0], payout1);
        verifyPayoutInfo(asset1Payouts[1], payout3);

        const asset2Payouts = await payoutManager.getPayoutsForAsset(asset2.address);
        expect(asset2Payouts.length).to.be.equal(2);
        verifyPayoutInfo(asset2Payouts[0], payout2);
        verifyPayoutInfo(asset2Payouts[1], payout4);

        // claim rewards for all accounts in payouts
        for (let i = 0; i < holders.length; i++) {
            await payoutManager.connect(alice).claim(payout1.id, holders[i], balances[i], proofs[i]); // claims 1:1
            await payoutManager.connect(alice).claim(payout2.id, holders[i], balances[i], proofs[i]); // claims 2:1
            await payoutManager.connect(alice).claim(payout3.id, holders[i], balances[i], proofs[i]); // claims 1:1
            await payoutManager.connect(alice).claim(payout4.id, holders[i], balances[i], proofs[i]); // claims 1:1
            // total claims = 5:1
        }
        
        // verify claimed rewards
        for (let i = 0; i < holders.length; i++) {
            const balance = await rewardAsset.balanceOf(holders[i]);
            expect(balance).to.be.equal(balances[i] * 5);
        }

        // verify remaining reward amount is now zero
        const afterPayoutInfo1 = await payoutManager.getPayoutInfo(payout1.id);
        verifyPayoutInfo(afterPayoutInfo1, {...payout1, remainingReward: 0});

        const afterPayoutInfo2 = await payoutManager.getPayoutInfo(payout2.id);
        verifyPayoutInfo(afterPayoutInfo2, {...payout2, remainingReward: 0});

        const afterPayoutInfo3 = await payoutManager.getPayoutInfo(payout3.id);
        verifyPayoutInfo(afterPayoutInfo3, {...payout3, remainingReward: 0});

        const afterPayoutInfo4 = await payoutManager.getPayoutInfo(payout4.id);
        verifyPayoutInfo(afterPayoutInfo4, {...payout4, remainingReward: 0});
    });

    it('should cancel payout which did not issue any rewards yet', async function() {
        const ownerAddress = await payoutOwner1.getAddress();

        // transfer reward token to payoutOwner1
        await rewardAsset.connect(assetDistributor).transfer(ownerAddress, oneToOneReward);

        // payoutOwner1 approves reward for payout
        await rewardAsset.connect(payoutOwner1).approve(payoutManager.address, oneToOneReward);

        const payout: Payout = {
            id: 0,
            owner: ownerAddress,
            canceled: false,
            asset: asset1.address,
            totalReward: oneToOneReward,
            remainingReward: oneToOneReward
        }

        // payoutOwner1 creates payout for asset1
        const createPayout = preparePayout(payoutOwner1, payout);

        // verify PayoutCreated event data
        await verifyCreatePayoutEvent(createPayout, payout);

        // verify payout info by ID
        const payoutInfo = await payoutManager.getPayoutInfo(payout.id);
        verifyPayoutInfo(payoutInfo, payout);

        // verify payout info per asset
        const assetPayouts = await payoutManager.getPayoutsForAsset(asset1.address);
        expect(assetPayouts.length).to.be.equal(1);
        verifyPayoutInfo(assetPayouts[0], payout);

        // cancel payout
        const cencelPayout = payoutManager.connect(payoutOwner1).cancelPayout(payout.id);

        // verify cancel payout event
        await expect(cencelPayout).to.emit(payoutManager, "PayoutCanceled").withArgs(
            payout.id,
            payout.asset
        );

        // verify funds are returned to owner
        const ownerBalance = await rewardAsset.balanceOf(ownerAddress);
        expect(ownerBalance).to.be.equal(oneToOneReward);

        // verify remaining reward amount is now zero and payout is canceled
        const afterPayoutInfo = await payoutManager.getPayoutInfo(payout.id);
        verifyPayoutInfo(afterPayoutInfo, {...payout, canceled: true, remainingReward: 0});
    });

    it('should cancel payout after some rewards have already been issued', async function() {
        const ownerAddress = await payoutOwner1.getAddress();

        // transfer reward token to payoutOwner1
        await rewardAsset.connect(assetDistributor).transfer(ownerAddress, oneToOneReward);

        // payoutOwner1 approves reward for payout
        await rewardAsset.connect(payoutOwner1).approve(payoutManager.address, oneToOneReward);

        const payout: Payout = {
            id: 0,
            owner: ownerAddress,
            canceled: false,
            asset: asset1.address,
            totalReward: oneToOneReward,
            remainingReward: oneToOneReward
        }

        // payoutOwner1 creates payout for asset1
        const createPayout = preparePayout(payoutOwner1, payout);

        // verify PayoutCreated event data
        await verifyCreatePayoutEvent(createPayout, payout);

        // verify payout info by ID
        const payoutInfo = await payoutManager.getPayoutInfo(payout.id);
        verifyPayoutInfo(payoutInfo, payout);

        // verify payout info per asset
        const assetPayouts = await payoutManager.getPayoutsForAsset(asset1.address);
        expect(assetPayouts.length).to.be.equal(1);
        verifyPayoutInfo(assetPayouts[0], payout);

        // claim one rewards in the payout
        await payoutManager.connect(alice).claim(payout.id, holders[0], balances[0], proofs[0]);
        
        // verify claimed reward
        const balance = await rewardAsset.balanceOf(holders[0]);
        expect(balance).to.be.equal(balances[0]);

        // cancel payout
        const cencelPayout = payoutManager.connect(payoutOwner1).cancelPayout(payout.id);

        // verify cancel payout event
        await expect(cencelPayout).to.emit(payoutManager, "PayoutCanceled").withArgs(
            payout.id,
            payout.asset
        );

        // verify funds are returned to owner
        const ownerBalance = await rewardAsset.balanceOf(ownerAddress);
        expect(ownerBalance).to.be.equal(oneToOneReward - balances[0]); // minus claimed reward

        // verify remaining reward amount is now zero and payout is canceled
        const afterPayoutInfo = await payoutManager.getPayoutInfo(payout.id);
        verifyPayoutInfo(afterPayoutInfo, {...payout, canceled: true, remainingReward: 0});
    });

    it('should not be able to cancel non-existent payout', async function() {
        const cencelPayout = payoutManager.connect(payoutOwner1).cancelPayout(123);
        await expect(cencelPayout).to.be.revertedWith("PayoutManager: payout with specified ID doesn't exist");
    });

    it('should not be able to cancel payout for non-owner', async function() {
        const ownerAddress = await payoutOwner1.getAddress();

        // transfer reward token to payoutOwner1
        await rewardAsset.connect(assetDistributor).transfer(ownerAddress, oneToOneReward);

        // payoutOwner1 approves reward for payout
        await rewardAsset.connect(payoutOwner1).approve(payoutManager.address, oneToOneReward);

        const payout: Payout = {
            id: 0,
            owner: ownerAddress,
            canceled: false,
            asset: asset1.address,
            totalReward: oneToOneReward,
            remainingReward: oneToOneReward
        }

        // payoutOwner1 creates payout for asset1
        const createPayout = preparePayout(payoutOwner1, payout);

        // verify PayoutCreated event data
        await verifyCreatePayoutEvent(createPayout, payout);

        // verify that other user cannot cancel payout
        const cencelPayout = payoutManager.connect(alice).cancelPayout(payout.id);
        await expect(cencelPayout).to.be.revertedWith("PayoutManager: requesting address is not payout owner");
    });

    it('should not be able to cancel already canceled payout', async function() {
        const ownerAddress = await payoutOwner1.getAddress();

        // transfer reward token to payoutOwner1
        await rewardAsset.connect(assetDistributor).transfer(ownerAddress, oneToOneReward);

        // payoutOwner1 approves reward for payout
        await rewardAsset.connect(payoutOwner1).approve(payoutManager.address, oneToOneReward);

        const payout: Payout = {
            id: 0,
            owner: ownerAddress,
            canceled: false,
            asset: asset1.address,
            totalReward: oneToOneReward,
            remainingReward: oneToOneReward
        }

        // payoutOwner1 creates payout for asset1
        const createPayout = preparePayout(payoutOwner1, payout);

        // verify PayoutCreated event data
        await verifyCreatePayoutEvent(createPayout, payout);

        // cancel payout
        const cencelPayout = payoutManager.connect(payoutOwner1).cancelPayout(payout.id);

        // verify cancel payout event
        await expect(cencelPayout).to.emit(payoutManager, "PayoutCanceled").withArgs(
            payout.id,
            payout.asset
        );

        // verify funds are returned to owner
        const ownerBalance = await rewardAsset.balanceOf(ownerAddress);
        expect(ownerBalance).to.be.equal(oneToOneReward);

        // verify that payout cannot be canceled again
        const cencelPayoutAgain = payoutManager.connect(payoutOwner1).cancelPayout(payout.id);
        await expect(cencelPayoutAgain).to.be.revertedWith("PayoutManager: payout with specified ID is canceled");
    });

    it('should not allow claim for non-existent payout', async function() {
        const claim = payoutManager.connect(alice).claim(123, holders[0], balances[0], proofs[0]);
        await expect(claim).to.be.revertedWith("PayoutManager: payout with specified ID doesn't exist");
    });

    it('should not allow claim for canceled payout', async function() {
        const ownerAddress = await payoutOwner1.getAddress();

        // transfer reward token to payoutOwner1
        await rewardAsset.connect(assetDistributor).transfer(ownerAddress, oneToOneReward);

        // payoutOwner1 approves reward for payout
        await rewardAsset.connect(payoutOwner1).approve(payoutManager.address, oneToOneReward);

        const payout: Payout = {
            id: 0,
            owner: ownerAddress,
            canceled: false,
            asset: asset1.address,
            totalReward: oneToOneReward,
            remainingReward: oneToOneReward
        }

        // payoutOwner1 creates payout for asset1
        const createPayout = preparePayout(payoutOwner1, payout);

        // verify PayoutCreated event data
        await verifyCreatePayoutEvent(createPayout, payout);

        // verify payout info by ID
        const payoutInfo = await payoutManager.getPayoutInfo(payout.id);
        verifyPayoutInfo(payoutInfo, payout);

        // verify payout info per asset
        const assetPayouts = await payoutManager.getPayoutsForAsset(asset1.address);
        expect(assetPayouts.length).to.be.equal(1);
        verifyPayoutInfo(assetPayouts[0], payout);

        // cancel payout
        const cencelPayout = payoutManager.connect(payoutOwner1).cancelPayout(payout.id);

        // verify cancel payout event
        await expect(cencelPayout).to.emit(payoutManager, "PayoutCanceled").withArgs(
            payout.id,
            payout.asset
        );

        // verify funds are returned to owner
        const ownerBalance = await rewardAsset.balanceOf(ownerAddress);
        expect(ownerBalance).to.be.equal(oneToOneReward);

        // verify remaining reward amount is now zero and payout is canceled
        const afterPayoutInfo = await payoutManager.getPayoutInfo(payout.id);
        verifyPayoutInfo(afterPayoutInfo, {...payout, canceled: true, remainingReward: 0});

        // verify that rewards cannot be claimed
        const claim = payoutManager.connect(alice).claim(payout.id, holders[0], balances[0], proofs[0]);
        await expect(claim).to.be.revertedWith("PayoutManager: payout with specified ID is canceled");
    });

    it('should not allow multiple claim for single payout', async function() {
        const ownerAddress = await payoutOwner1.getAddress();

        // transfer reward token to payoutOwner1
        await rewardAsset.connect(assetDistributor).transfer(ownerAddress, oneToOneReward);

        // payoutOwner1 approves reward for payout
        await rewardAsset.connect(payoutOwner1).approve(payoutManager.address, oneToOneReward);

        const payout: Payout = {
            id: 0,
            owner: ownerAddress,
            canceled: false,
            asset: asset1.address,
            totalReward: oneToOneReward,
            remainingReward: oneToOneReward
        }

        // payoutOwner1 creates payout for asset1
        const createPayout = preparePayout(payoutOwner1, payout);

        // verify PayoutCreated event data
        await verifyCreatePayoutEvent(createPayout, payout);

        // verify payout info by ID
        const payoutInfo = await payoutManager.getPayoutInfo(payout.id);
        verifyPayoutInfo(payoutInfo, payout);

        // verify payout info per asset
        const assetPayouts = await payoutManager.getPayoutsForAsset(asset1.address);
        expect(assetPayouts.length).to.be.equal(1);
        verifyPayoutInfo(assetPayouts[0], payout);

        // claim reward for account included in the payout
        await payoutManager.connect(alice).claim(payout.id, holders[0], balances[0], proofs[0]);

        // verify that reward cannot be claimed again
        const claim = payoutManager.connect(alice).claim(payout.id, holders[0], balances[0], proofs[0]);
        await expect(claim).to.be.revertedWith("PayoutManager: payout with specified ID is already claimed for specified wallet");
    });

    it('should not allow claim for account included in payout with incorrect balance', async function() {
        const ownerAddress = await payoutOwner1.getAddress();

        // transfer reward token to payoutOwner1
        await rewardAsset.connect(assetDistributor).transfer(ownerAddress, oneToOneReward);

        // payoutOwner1 approves reward for payout
        await rewardAsset.connect(payoutOwner1).approve(payoutManager.address, oneToOneReward);

        const payout: Payout = {
            id: 0,
            owner: ownerAddress,
            canceled: false,
            asset: asset1.address,
            totalReward: oneToOneReward,
            remainingReward: oneToOneReward
        }

        // payoutOwner1 creates payout for asset1
        const createPayout = preparePayout(payoutOwner1, payout);

        // verify PayoutCreated event data
        await verifyCreatePayoutEvent(createPayout, payout);

        // verify payout info by ID
        const payoutInfo = await payoutManager.getPayoutInfo(payout.id);
        verifyPayoutInfo(payoutInfo, payout);

        // verify payout info per asset
        const assetPayouts = await payoutManager.getPayoutsForAsset(asset1.address);
        expect(assetPayouts.length).to.be.equal(1);
        verifyPayoutInfo(assetPayouts[0], payout);

        // verify that incorrect reward amount cannot be claimed
        const claim = payoutManager.connect(alice).claim(payout.id, holders[0], balances[0] * 2, proofs[0]);
        await expect(claim).to.be.revertedWith("PayoutManager: requested (address, blaance) pair is not contained in specified payout");
    });

    it('should not allow claim for account not included in payout', async function() {
        const ownerAddress = await payoutOwner1.getAddress();

        // transfer reward token to payoutOwner1
        await rewardAsset.connect(assetDistributor).transfer(ownerAddress, oneToOneReward);

        // payoutOwner1 approves reward for payout
        await rewardAsset.connect(payoutOwner1).approve(payoutManager.address, oneToOneReward);

        const payout: Payout = {
            id: 0,
            owner: ownerAddress,
            canceled: false,
            asset: asset1.address,
            totalReward: oneToOneReward,
            remainingReward: oneToOneReward
        }

        // payoutOwner1 creates payout for asset1
        const createPayout = preparePayout(payoutOwner1, payout);

        // verify PayoutCreated event data
        await verifyCreatePayoutEvent(createPayout, payout);

        // verify payout info by ID
        const payoutInfo = await payoutManager.getPayoutInfo(payout.id);
        verifyPayoutInfo(payoutInfo, payout);

        // verify payout info per asset
        const assetPayouts = await payoutManager.getPayoutsForAsset(asset1.address);
        expect(assetPayouts.length).to.be.equal(1);
        verifyPayoutInfo(assetPayouts[0], payout);

        // verify that account not included in payout cannot claim reward
        const nonIncludedAddress = await alice.getAddress();
        const claim = payoutManager.connect(alice).claim(payout.id, nonIncludedAddress, 2500, proofs[0]);
        await expect(claim).to.be.revertedWith("PayoutManager: requested (address, blaance) pair is not contained in specified payout");
    });
})

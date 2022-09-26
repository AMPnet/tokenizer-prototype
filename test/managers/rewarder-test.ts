// @ts-ignore
import { ethers } from "hardhat";
import { Contract, Signer } from "ethers";
import * as helpers from "../../util/helpers";
import { expect } from "chai";
import { describe, it } from "mocha";
import { Rewarder, USDC } from "../../typechain";
import { solidityKeccak256 } from "ethers/lib/utils";
import { advanceBlockTime } from "../../util/utils";

describe("Rewarder test", function () {

    let rewarder: Rewarder
    let usdc: USDC
    let owner: Signer
    let ownerAddress: string
    let claimer: Signer
    let claimerAddress: string

    beforeEach(async function () {
        const accounts: Signer[] = await ethers.getSigners();
        owner       = accounts[0];
        claimer     = accounts[1];
        ownerAddress = await owner.getAddress();
        claimerAddress = await claimer.getAddress();

        let rewarderFactory = await ethers.getContractFactory("Rewarder", owner);
        rewarder = await rewarderFactory.deploy(ownerAddress);
        usdc = (await helpers.deployStablecoin(owner, 1000, 18)) as USDC;

        usdc.connect(owner).transfer(rewarder.address, await helpers.parseStablecoin(10, usdc));
        await owner.sendTransaction({
            to: rewarder.address,
            value: ethers.utils.parseUnits("10", "ether")
        });
        console.log("native balance", (await ethers.provider.getBalance(rewarder.address)).toString());
        console.log("usdc balance", (await usdc.balanceOf(rewarder.address)).toString());
    });

    it('is possible to claim reward using the valid key', async () => {
        const secretKey = "secret-key";
        const hash = solidityKeccak256(["address", "string"], [rewarder.address, secretKey]);
        const usdcRewardAmount = await helpers.parseStablecoin("1", usdc);
        const nativeRewardAmount = usdcRewardAmount;
        const expiresAt = Date.now() + 100; // expires in 100 seconds
        
        const forbiddenAddReward = rewarder.connect(claimer).addRewards([
            {
                secretHash: hash,
                token: usdc.address,
                amount: usdcRewardAmount,
                nativeAmount: nativeRewardAmount,
                expiresAt: expiresAt
            }
        ]);
        await expect(forbiddenAddReward).to.be.revertedWith("Ownable: caller is not the owner");

        await rewarder.addRewards([
            {
                secretHash: hash,
                token: usdc.address,
                amount: usdcRewardAmount,
                nativeAmount: nativeRewardAmount,
                expiresAt: expiresAt
            }
        ]);

        const nonexistingKeyClaim = rewarder.connect(claimer).claimReward("non-existing-key");
        await expect(nonexistingKeyClaim).to.be.revertedWith("Key does not exist!");

        const claimerNativeBalancePreClaim = await ethers.provider.getBalance(claimerAddress)
        await rewarder.connect(claimer).claimReward(secretKey);
        expect(await usdc.balanceOf(claimerAddress)).to.be.equal(usdcRewardAmount);
        expect((await ethers.provider.getBalance(claimerAddress)).gt(claimerNativeBalancePreClaim)).to.be.true;

        const repeatedClaim = rewarder.connect(claimer).claimReward(secretKey);
        await expect(repeatedClaim).to.be.revertedWith("Reward with this key already claimed!");

        const forbiddenDrainToken = rewarder.connect(claimer)["drain(address)"](usdc.address);
        await expect(forbiddenDrainToken).to.be.revertedWith("Ownable: caller is not the owner");

        const forbiddenDrainNativeToken = rewarder.connect(claimer)["drain()"]();
        await expect(forbiddenDrainNativeToken).to.be.revertedWith("Ownable: caller is not the owner");

        const expiredKey = "expired-key";
        const expiredHash = solidityKeccak256(["address", "string"], [rewarder.address, expiredKey]);
        const expiredTimestamp = Date.now() + 10; // expires in 10 seconds
        await rewarder.addRewards([
            {
                secretHash: expiredHash,
                token: usdc.address,
                amount: usdcRewardAmount,
                nativeAmount: nativeRewardAmount,
                expiresAt: expiredTimestamp
            }
        ]);
        await advanceBlockTime(expiredTimestamp + 1);
        const expiredRewardClaim = rewarder.connect(claimer).claimReward(expiredKey);
        await expect(expiredRewardClaim).to.be.revertedWith("Reward expired!");

        const ownerUsdcBalanceBeforeDrain = await usdc.balanceOf(ownerAddress);
        const ownerNativeBalanceBeforeDrain = await ethers.provider.getBalance(ownerAddress);
        await rewarder["drain(address)"](usdc.address);
        await rewarder["drain()"]();

        expect(await usdc.balanceOf(rewarder.address)).to.be.equal(0);
        expect(await ethers.provider.getBalance(rewarder.address)).to.be.equal(0);
        expect((await usdc.balanceOf(ownerAddress)).gt(ownerUsdcBalanceBeforeDrain)).to.be.true;
        expect((await ethers.provider.getBalance(ownerAddress)).gt(ownerNativeBalanceBeforeDrain)).to.be.true;
    });

});
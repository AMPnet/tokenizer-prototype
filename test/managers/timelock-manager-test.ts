// @ts-ignore
import {ethers} from "hardhat";
import {BigNumber, Signer} from "ethers";
import * as helpers from "../../util/helpers";
import {expect} from "chai";
import {TimeLockManager, IERC20} from "../../typechain";
import {describe, it} from "mocha";
import {advanceBlockTime} from "../../util/utils";

describe("TimeLock Manager tests", function () {

    var accounts: Signer[];
    var token: IERC20;

    async function createTimeLockManager(): Promise<TimeLockManager> {
        const TimeLockManagerContract = await ethers.getContractFactory("TimeLockManager", accounts[0]);
        const deployed = await TimeLockManagerContract.deploy();
        return deployed as TimeLockManager;
    }
    
    async function now(): Promise<number> {
        const latest = await ethers.provider.getBlock("latest");
        return latest.timestamp;
    }

    before(async function () {
        accounts = await ethers.getSigners();
    });

    beforeEach(async function () {
        token = await helpers.deployStablecoin(accounts[0], "1000000", 18) as IERC20;
    });

    it(`will fail to lock tokens if missing approval`, async () => {
        const timeLockManager = await createTimeLockManager();
        const forbiddenLockTx = timeLockManager.lock(token.address, 10, 10, "info");
        await expect(forbiddenLockTx).to.be.revertedWith("TimeLockManager:: missing allowance");
    });

    it(`will successfully lock tokens if the lockup period is > 0 & token amount is > 0`, async () => {
        const duration = 10;
        const deadline = (await now()) + duration;
        const amountToLock = BigNumber.from(1);
        const lockDescription = "info";
        const timeLockManager = await createTimeLockManager();
        
        // make sure spender has 0 tokens in the beginning
        const spender = accounts[1];
        const spenderAddress = await spender.getAddress();
        expect(await token.balanceOf(spenderAddress)).to.be.equal(0);

        // spender acquires 1 token
        await token.transfer(spenderAddress, amountToLock);
        expect(await token.balanceOf(spenderAddress)).to.be.equal(amountToLock);

        // spender locks 1 token
        await token.connect(spender).approve(timeLockManager.address, amountToLock);
        const lockTx = await timeLockManager.connect(spender).lock(
            token.address,
            amountToLock,
            duration,
            lockDescription
        );
        await expect(lockTx).to.emit(timeLockManager, "Lock").withArgs(
            spenderAddress,
            token.address,
            amountToLock,
            duration
        );
        expect(await token.balanceOf(spenderAddress)).to.be.equal(0);
        expect(await token.balanceOf(timeLockManager.address)).to.be.equal(amountToLock);

        const tokenLockEntry = await timeLockManager.locks(spenderAddress, 0);
        expect(tokenLockEntry.token).to.be.equal(token.address);
        expect(tokenLockEntry.amount).to.be.equal(amountToLock);
        expect(tokenLockEntry.createdAt).to.exist;
        expect(tokenLockEntry.duration).to.be.equal(duration);
        expect(tokenLockEntry.info).to.be.equal(lockDescription);
        expect(tokenLockEntry.released).to.be.false;

        // spender tries to unlock before deadline has been reached (must fail)
        const forbiddenUnlockTx = timeLockManager.connect(spender).unlock(spenderAddress, 0);
        await expect(forbiddenUnlockTx).to.be.revertedWith("TimeLockManager:: deadline not reached");

        // fast forward to future when deadline is reached and the spender can unlock his tokens
        await advanceBlockTime(deadline + 10);
        const unlockTx = await timeLockManager.unlock(spenderAddress, 0);
        await expect(unlockTx).to.emit(timeLockManager, "Unlock").withArgs(
            spenderAddress,
            token.address,
            0,
            amountToLock
        );
        expect(await token.balanceOf(spenderAddress)).to.be.equal(amountToLock);
        expect(await token.balanceOf(timeLockManager.address)).to.be.equal(0);

        const tokenLockEntryAfterRelease = await timeLockManager.locks(spenderAddress, 0);
        expect(tokenLockEntryAfterRelease.token).to.be.equal(token.address);
        expect(tokenLockEntryAfterRelease.amount).to.be.equal(amountToLock);
        expect(tokenLockEntryAfterRelease.createdAt).to.exist;
        expect(tokenLockEntryAfterRelease.duration).to.be.equal(duration);
        expect(tokenLockEntryAfterRelease.info).to.be.equal(lockDescription);
        expect(tokenLockEntryAfterRelease.released).to.be.true;

        // it will fail if user tries to release tokens again
        const failedUnlockTx = timeLockManager.unlock(spenderAddress, 0);
        await expect(failedUnlockTx).to.be.revertedWith("TimeLockManager:: tokens already released");

        // can fetch the list of the token locks for the user 
        const lockHistory = await timeLockManager.tokenLocksList(spenderAddress);
        expect(lockHistory.length).to.be.equal(1);
        const tokenLockEntryFromHistory = lockHistory[0];
        expect(tokenLockEntryFromHistory.token).to.be.equal(token.address);
        expect(tokenLockEntryFromHistory.amount).to.be.equal(amountToLock);
        expect(tokenLockEntryFromHistory.createdAt).to.exist;
        expect(tokenLockEntryFromHistory.duration).to.be.equal(duration);
        expect(tokenLockEntryFromHistory.info).to.be.equal(lockDescription);
        expect(tokenLockEntryFromHistory.released).to.be.true;
    });

});

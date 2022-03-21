// @ts-ignore
import {ethers} from "hardhat";
import {BigNumber, Contract, Signer, utils} from "ethers";
import * as helpers from "../../util/helpers";
import {expect, util} from "chai";
import {TimeLockManager, IERC20} from "../../typechain";
import {describe, it} from "mocha";
import {advanceBlockTime} from "../../util/utils";

describe("TimeLock Manager tests", function () {

    var accounts: Signer[];
    var token: IERC20;

    async function createTimeLockManager(
        token: string,
        deadline: number
    ): Promise<TimeLockManager> {
        const TimeLockManagerContract = await ethers.getContractFactory("TimeLockManager", accounts[0]);
        const deployed = await TimeLockManagerContract.deploy(token, deadline);
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

    it(`is forbidden to create a TimeLock manager with the unlock deadline in the past`, async () => {
        const forbiddenCreateTx = createTimeLockManager(
            token.address,
            (await now()) - 1
        );
        await expect(forbiddenCreateTx).to.be.revertedWith("TimeLockManager:: deadline must be in the future");
    });

    it(`is forbidden to create a TimeLock manager with the zero address token`, async () => {
        const forbiddenCreateTx = createTimeLockManager(
            ethers.constants.AddressZero,
            (await now()) + 1
        );
        await expect(forbiddenCreateTx).to.be.revertedWith("TimeLockManager:: token is 0x0");
    });

    it(`will fail to lock tokens if amount is 0`, async () => {
        const timeLockManager = await createTimeLockManager(
            token.address,
            (await now()) + 100
        );
        const forbiddenLockTx = timeLockManager.lock(0);
        await expect(forbiddenLockTx).to.be.revertedWith("TimeLockManager: amount is  0");
    });

    it(`will fail to lock tokens if missing approval`, async () => {
        const timeLockManager = await createTimeLockManager(
            token.address,
            (await now()) + 100
        );
        const forbiddenLockTx = timeLockManager.lock(10);
        await expect(forbiddenLockTx).to.be.revertedWith("TimeLockManager:: allowance is 0");
    });

    it(`will fail to lock tokens if unlock deadline has been reached`, async () => {
        const deadline = (await now()) + 10;
        const amountToLock = 1;
        const timeLockManager = await createTimeLockManager(
            token.address,
            deadline
        );
        await advanceBlockTime(deadline + 1); // go into the future to reach the unlock deadline
        await token.connect(accounts[0]).approve(timeLockManager.address, amountToLock);
        const forbiddenLockTx = timeLockManager.lock(amountToLock);
        await expect(forbiddenLockTx).to.be.revertedWith("TimeLockManager:: manager expired");
    });

    it(`will successfully lock tokens if the unlock deadline has not been reached`, async () => {
        const deadline = (await now()) + 10;
        const amountToLock = BigNumber.from(1);
        const timeLockManager = await createTimeLockManager(
            token.address,
            deadline
        );
        
        // make sure spender has 0 tokens in the beginning
        const spender = accounts[1];
        const spenderAddress = await spender.getAddress();
        expect(await token.balanceOf(spenderAddress)).to.be.equal(0);

        // spender acquires 1 token
        await token.transfer(spenderAddress, amountToLock);
        expect(await token.balanceOf(spenderAddress)).to.be.equal(amountToLock);

        // spender locks 1 token
        await token.connect(spender).approve(timeLockManager.address, amountToLock);
        const lockTx = await timeLockManager.connect(spender).lock(amountToLock);
        await expect(lockTx).to.emit(timeLockManager, "Lock").withArgs(spenderAddress, amountToLock);
        expect(await token.balanceOf(spenderAddress)).to.be.equal(0);
        expect(await timeLockManager.locks(spenderAddress)).to.be.equal(amountToLock);
        expect(await token.balanceOf(timeLockManager.address)).to.be.equal(amountToLock);

        // spender tries to unlock before deadline has been reached (must fail)
        const forbiddenUnlockTx = timeLockManager.connect(spender).unlock(spenderAddress);
        await expect(forbiddenUnlockTx).to.be.revertedWith("TimeLockManager:: deadline not reached");

        // fast forward to future when deadline is reached and the spender can unlock his tokens
        await advanceBlockTime(deadline + 1);
        const unlockTx = await timeLockManager.unlock(spenderAddress);
        await expect(unlockTx).to.emit(timeLockManager, "Unlock").withArgs(spenderAddress, amountToLock);
        expect(await token.balanceOf(spenderAddress)).to.be.equal(amountToLock);
        expect(await timeLockManager.locks(spenderAddress)).to.be.equal(0);
        expect(await token.balanceOf(timeLockManager.address)).to.be.equal(0);
    });

    it(`will fail to unlock tokens if 0 tokens are locked`, async () => {
        const deadline = (await now()) + 10;
        const timeLockManager = await createTimeLockManager(
            token.address,
            deadline
        );
        await advanceBlockTime(deadline + 1);
        const forbiddenUnlockTx = timeLockManager.unlock(await accounts[0].getAddress());
        await expect(forbiddenUnlockTx).to.be.revertedWith("TimeLockManager:: locked amount is 0");
    });

});

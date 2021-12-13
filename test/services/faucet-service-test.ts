// @ts-ignore
import { ethers } from "hardhat";
import { providers, Signer } from "ethers";
import { expect } from "chai";
import { describe, it } from "mocha";
import { FaucetService } from "../../typechain";

describe("Faucet service test", function () {

    //////// CONTRACTS ////////
    let faucetService: FaucetService;
    
    //////// SIGNERS ////////
    let masterOwner: Signer;
    let caller1: Signer;
    let caller2: Signer;
    let alice: Signer;
    let bob: Signer;
    let jane: Signer;
    let frank: Signer;

    //////// CONST ////////
    const defaultRewardPerApprove = ethers.utils.parseUnits("10000", "wei"); // 10k wei reward
    const defaultBalanceThresholdForReward = ethers.utils.parseUnits("0", "wei");

    beforeEach(async function () {
        const accounts: Signer[] = await ethers.getSigners();

        masterOwner = accounts[0];
        caller1     = accounts[1];
        caller2     = accounts[2];
        alice       = ethers.Wallet.createRandom();
        bob         = ethers.Wallet.createRandom();
        jane        = ethers.Wallet.createRandom();
        frank       = ethers.Wallet.createRandom();

        const faucetServiceContractFactory = await ethers.getContractFactory("FaucetService", masterOwner);
        const allowedCallers = [await caller1.getAddress(), await caller2.getAddress()];
        const contract = await faucetServiceContractFactory.deploy(
            await masterOwner.getAddress(),
            allowedCallers,
            defaultRewardPerApprove,
            defaultBalanceThresholdForReward
        );

        faucetService = contract as FaucetService;
    });

    it('should be able to receive funds', async function() {
        // send funds from masterOwner
        await masterOwner.sendTransaction({
            to: faucetService.address,
            value: ethers.utils.parseUnits("10000", "wei")
        });

        // check contract balance
        const balance1 = await ethers.provider.getBalance(faucetService.address);
        expect(balance1).to.be.equal(ethers.utils.parseUnits("10000", "wei"));

        // send funds from caller1
        await caller1.sendTransaction({
            to: faucetService.address,
            value: ethers.utils.parseUnits("10000", "wei")
        });

        // check contract balance
        const balance2 = await ethers.provider.getBalance(faucetService.address);
        expect(balance2).to.be.equal(ethers.utils.parseUnits("20000", "wei"));
    });

    it('should be able to release funds', async function() {
        // get masterOwner inital balance
        const masterOwnerAddress = await masterOwner.getAddress();
        const initialMasterOwnerBalance = await ethers.provider.getBalance(masterOwnerAddress);

        // send funds from masterOwner
        const transaction1 = await masterOwner.sendTransaction({
            to: faucetService.address,
            value: ethers.utils.parseEther("1")
        });

        // check masterOwner balance after deposit
        const afterDepositMasterOwnerBalance = await ethers.provider.getBalance(masterOwnerAddress);
        expect(afterDepositMasterOwnerBalance).to.be.lt(initialMasterOwnerBalance);

        // check contract balance
        const contractBalance1 = await ethers.provider.getBalance(faucetService.address);
        expect(contractBalance1).to.be.equal(ethers.utils.parseEther("1"));

        // release funds as caller1 - not allowed
        await expect(
            faucetService.connect(caller1).release()
        ).to.be.revertedWith("FaucetService: not master owner");

        // get masterOwner balance before withdraw
        const beforeWithdrawMasterOwnerBalance = await ethers.provider.getBalance(masterOwnerAddress);

        // release funds as masterOwner
        await faucetService.connect(masterOwner).release()

        // check masterOwner balance after withdraw
        const afterWithdrawMasterOwnerBalance = await ethers.provider.getBalance(masterOwnerAddress);
        expect(afterWithdrawMasterOwnerBalance).to.be.gt(beforeWithdrawMasterOwnerBalance);

        // check contract balance
        const contractBalance2 = await ethers.provider.getBalance(faucetService.address);
        expect(contractBalance2).to.be.equal(ethers.utils.parseUnits("0", "wei"));
    });

    it('should be able to fund target wallets', async function() {
        // get addresses
        const aliceAddress = await alice.getAddress();
        const bobAddress = await bob.getAddress();
        const janeAddress = await jane.getAddress();
        const frankAddress = await frank.getAddress();

        // send funds from masterOwner
        await masterOwner.sendTransaction({
            to: faucetService.address,
            value: ethers.utils.parseEther("1")
        });

        // check contract balance
        const contractBalance = await ethers.provider.getBalance(faucetService.address);
        expect(contractBalance).to.be.equal(ethers.utils.parseEther("1"));

        // fund wallets as masterOwner
        await faucetService.connect(masterOwner).faucet([aliceAddress, bobAddress]);

        // check wallet balances
        expect(await ethers.provider.getBalance(aliceAddress)).to.be.equal(defaultRewardPerApprove);
        expect(await ethers.provider.getBalance(bobAddress)).to.be.equal(defaultRewardPerApprove);
        expect(await ethers.provider.getBalance(janeAddress)).to.be.equal(ethers.utils.parseUnits("0", "wei")); // not receiving now
        expect(await ethers.provider.getBalance(frankAddress)).to.be.equal(ethers.utils.parseUnits("0", "wei")); // not receiving now

        // fund wallets as caller1
        await faucetService.connect(caller1).faucet([janeAddress, frankAddress]);

        // check wallet balances
        expect(await ethers.provider.getBalance(aliceAddress)).to.be.equal(defaultRewardPerApprove);
        expect(await ethers.provider.getBalance(bobAddress)).to.be.equal(defaultRewardPerApprove);
        expect(await ethers.provider.getBalance(janeAddress)).to.be.equal(defaultRewardPerApprove);
        expect(await ethers.provider.getBalance(frankAddress)).to.be.equal(defaultRewardPerApprove);

        // fund already funded wallets as caller1
        await faucetService.connect(caller1).faucet([aliceAddress, bobAddress, janeAddress, frankAddress]);

        // check wallet balances - there should be no changes
        expect(await ethers.provider.getBalance(aliceAddress)).to.be.equal(defaultRewardPerApprove);
        expect(await ethers.provider.getBalance(bobAddress)).to.be.equal(defaultRewardPerApprove);
        expect(await ethers.provider.getBalance(janeAddress)).to.be.equal(defaultRewardPerApprove);
        expect(await ethers.provider.getBalance(frankAddress)).to.be.equal(defaultRewardPerApprove);
    });

    it('should be able to fund 100 different target wallets', async function() {
        // send funds from masterOwner
        await masterOwner.sendTransaction({
            to: faucetService.address,
            value: ethers.utils.parseEther("1")
        });

        // check contract balance
        const contractBalance = await ethers.provider.getBalance(faucetService.address);
        expect(contractBalance).to.be.equal(ethers.utils.parseEther("1"));

        // generate 100 random addresses
        const addresses = Array.from({length: 100}, () => ethers.Wallet.createRandom().address);

        // fund wallets as masterOwner
        await faucetService.connect(masterOwner).faucet(addresses);

        // check wallet balances
        for (const address of addresses) {
            expect(await ethers.provider.getBalance(address)).to.be.equal(defaultRewardPerApprove);
        }
    });

    it('should be able to update reward amount', async function() {
        // get addresses
        const aliceAddress = await alice.getAddress();
        const bobAddress = await bob.getAddress();
        const janeAddress = await jane.getAddress();
        const frankAddress = await frank.getAddress();

        // send funds from masterOwner
        await masterOwner.sendTransaction({
            to: faucetService.address,
            value: ethers.utils.parseEther("1")
        });

        // check contract balance
        const contractBalance = await ethers.provider.getBalance(faucetService.address);
        expect(contractBalance).to.be.equal(ethers.utils.parseEther("1"));

        // check reward value
        expect(await faucetService.rewardPerApprove()).to.be.equal(defaultRewardPerApprove);

        // fund wallets as masterOwner
        await faucetService.connect(masterOwner).faucet([aliceAddress, bobAddress]);

        // check wallet balances
        expect(await ethers.provider.getBalance(aliceAddress)).to.be.equal(defaultRewardPerApprove);
        expect(await ethers.provider.getBalance(bobAddress)).to.be.equal(defaultRewardPerApprove);
        expect(await ethers.provider.getBalance(janeAddress)).to.be.equal(ethers.utils.parseUnits("0", "wei")); // not receiving now
        expect(await ethers.provider.getBalance(frankAddress)).to.be.equal(ethers.utils.parseUnits("0", "wei")); // not receiving now

        // change reward amount as masterOwner
        const newReward = ethers.utils.parseUnits("35000", "wei");
        await faucetService.connect(masterOwner).updateRewardAmount(newReward);

        // check reward value
        expect(await faucetService.rewardPerApprove()).to.be.equal(newReward);

        // fund wallets as masterOwner
        await faucetService.connect(masterOwner).faucet([janeAddress, frankAddress]);

        // check wallet balances
        expect(await ethers.provider.getBalance(aliceAddress)).to.be.equal(defaultRewardPerApprove);
        expect(await ethers.provider.getBalance(bobAddress)).to.be.equal(defaultRewardPerApprove);
        expect(await ethers.provider.getBalance(janeAddress)).to.be.equal(newReward);
        expect(await ethers.provider.getBalance(frankAddress)).to.be.equal(newReward);

        // change reward amount as caller1 - should fail
        await expect(
            faucetService.connect(caller1).updateRewardAmount(newReward)
        ).to.be.revertedWith("FaucetService: not master owner");
    });

    it('should be able to update balance threshold for reward', async function() {
        // get addresses
        const aliceAddress = await alice.getAddress();

        // send funds from masterOwner
        await masterOwner.sendTransaction({
            to: faucetService.address,
            value: ethers.utils.parseEther("1")
        });

        // check contract balance
        const contractBalance = await ethers.provider.getBalance(faucetService.address);
        expect(contractBalance).to.be.equal(ethers.utils.parseEther("1"));

        // fund wallets as masterOwner
        await faucetService.connect(masterOwner).faucet([aliceAddress]);

        // check wallet balances
        expect(await ethers.provider.getBalance(aliceAddress)).to.be.equal(defaultRewardPerApprove);

        // update balance threshold for reward
        const newThreshold = defaultRewardPerApprove.mul("2");
        await faucetService.connect(masterOwner).updateBalanceThresholdForReward(newThreshold);

        // check balance threshold for reward
        expect(await faucetService.balanceThresholdForReward()).to.be.equal(newThreshold);

        // fund wallets as masterOwner when wallet balance < threshold 
        await faucetService.connect(masterOwner).faucet([aliceAddress]);

        // check wallet balances
        expect(await ethers.provider.getBalance(aliceAddress)).to.be.equal(defaultRewardPerApprove.mul("2"));

        // fund wallets as masterOwner when wallet balance == threshold 
        await faucetService.connect(masterOwner).faucet([aliceAddress]);

        // check wallet balances
        expect(await ethers.provider.getBalance(aliceAddress)).to.be.equal(defaultRewardPerApprove.mul("3"));

        // fund wallets as masterOwner when wallet balance > threshold 
        await faucetService.connect(masterOwner).faucet([aliceAddress]);

        // check wallet balances
        expect(await ethers.provider.getBalance(aliceAddress)).to.be.equal(defaultRewardPerApprove.mul("3")); // no new funds received

        // update balance threshold for reward as caller1 - should fail
        await expect(
            faucetService.connect(caller1).updateBalanceThresholdForReward(newThreshold)
        ).to.be.revertedWith("FaucetService: not master owner");
    });

    it('should be able to update caller status', async function() {
        // get addresses
        const aliceAddress = await alice.getAddress();
        const bobAddress = await bob.getAddress();
        const janeAddress = await jane.getAddress();
        const frankAddress = await frank.getAddress();

        // send funds from masterOwner
        await masterOwner.sendTransaction({
            to: faucetService.address,
            value: ethers.utils.parseEther("1")
        });

        // check contract balance
        const contractBalance = await ethers.provider.getBalance(faucetService.address);
        expect(contractBalance).to.be.equal(ethers.utils.parseEther("1"));

        // check allowed callers
        const caller1Address = await caller1.getAddress();
        const caller2Address = await caller2.getAddress();
        expect(await faucetService.allowedCallers(caller1Address)).to.be.equal(true);
        expect(await faucetService.allowedCallers(caller2Address)).to.be.equal(true);

        // fund wallets as caller1
        await faucetService.connect(caller1).faucet([aliceAddress]);

        // fund wallets as caller2
        await faucetService.connect(caller2).faucet([bobAddress]);

        // check wallet balances
        expect(await ethers.provider.getBalance(aliceAddress)).to.be.equal(defaultRewardPerApprove);
        expect(await ethers.provider.getBalance(bobAddress)).to.be.equal(defaultRewardPerApprove);
        expect(await ethers.provider.getBalance(janeAddress)).to.be.equal(ethers.utils.parseUnits("0", "wei")); // not receiving now
        expect(await ethers.provider.getBalance(frankAddress)).to.be.equal(ethers.utils.parseUnits("0", "wei")); // not receiving now

        // remove caller2 as allowed caller
        await faucetService.connect(masterOwner).updateCallerStatus(caller2Address, false);

        // check allowed callers
        expect(await faucetService.allowedCallers(caller1Address)).to.be.equal(true);
        expect(await faucetService.allowedCallers(caller2Address)).to.be.equal(false);

        // fund wallets as caller1
        await faucetService.connect(caller1).faucet([janeAddress]);

        // fund wallets as caller2
        await expect(
            faucetService.connect(caller2).faucet([frankAddress])
        ).to.be.revertedWith("FaucetService: not allowed to call function");

        // check wallet balances
        expect(await ethers.provider.getBalance(aliceAddress)).to.be.equal(defaultRewardPerApprove);
        expect(await ethers.provider.getBalance(bobAddress)).to.be.equal(defaultRewardPerApprove);
        expect(await ethers.provider.getBalance(janeAddress)).to.be.equal(defaultRewardPerApprove);
        expect(await ethers.provider.getBalance(frankAddress)).to.be.equal(ethers.utils.parseUnits("0", "wei")); // not receiving now

        // add caller2 as allowed caller
        await faucetService.connect(masterOwner).updateCallerStatus(caller2Address, true);

        // check allowed callers
        expect(await faucetService.allowedCallers(caller1Address)).to.be.equal(true);
        expect(await faucetService.allowedCallers(caller2Address)).to.be.equal(true);

        // fund wallets as caller2
        await faucetService.connect(caller2).faucet([frankAddress]);

        // check wallet balances
        expect(await ethers.provider.getBalance(aliceAddress)).to.be.equal(defaultRewardPerApprove);
        expect(await ethers.provider.getBalance(bobAddress)).to.be.equal(defaultRewardPerApprove);
        expect(await ethers.provider.getBalance(janeAddress)).to.be.equal(defaultRewardPerApprove);
        expect(await ethers.provider.getBalance(frankAddress)).to.be.equal(defaultRewardPerApprove);

        // remove caller1 as allowed caller as caller2 - not allowed
        await expect(
            faucetService.connect(caller2).updateCallerStatus(caller1Address, false)
        ).to.be.revertedWith("FaucetService: not master owner");
    });

    it('should be able to transfer ownership', async function () {
        const masterOwnerAddress = await masterOwner.getAddress();
        const caller1Address = await caller1.getAddress();

        // owner = masterOwner; caller1 not allowed to transfer ownership
        await expect(
            faucetService.connect(caller1).transferOwnership(caller1Address)
        ).to.be.revertedWith("FaucetService: not master owner");

        // check owner
        expect(await faucetService.masterOwner()).to.be.equal(masterOwnerAddress);

        // owner = masterOwner; transfering to caller1
        expect(
            await faucetService.connect(masterOwner).transferOwnership(caller1Address)
        ).to.be.ok;

        // check owner
        expect(await faucetService.masterOwner()).to.be.equal(caller1Address);

        // owner = caller1; masterOwner not allowed to transfer ownership
        await expect(
            faucetService.connect(masterOwner).transferOwnership(masterOwnerAddress)
        ).to.be.revertedWith("FaucetService: not master owner");

        // check owner
        expect(await faucetService.masterOwner()).to.be.equal(caller1Address);

        // owner = caller1; transfering to masterOwner
        expect(
            await faucetService.connect(caller1).transferOwnership(masterOwnerAddress)
        ).to.be.ok;

        // check owner
        expect(await faucetService.masterOwner()).to.be.equal(masterOwnerAddress);
    });
})

// @ts-ignore
import {ethers} from "hardhat";
import {Contract, Signer} from "ethers";
import * as helpers from "../../util/helpers";
import {expect} from "chai";
import {describe, it} from "mocha";

describe("Fee Manager test", function () {

    let manager: Signer
    let treasury: Signer
    let jane: Signer
    let feeManagerContract: Contract

    beforeEach(async function () {
        const accounts: Signer[] = await ethers.getSigners();
        manager     = accounts[0];
        treasury    = accounts[1];
        jane        = accounts[2];

        feeManagerContract = await helpers.deployFeeManager(
            manager,
            await manager.getAddress(),
            await treasury.getAddress()
        );
    })

    it("should verify isManager modifier", async function () {
        const modifierMessage = "!manager";
        const address = await jane.getAddress();

        await expect(
            feeManagerContract.connect(jane).updateTreasury(address)
        ).to.be.revertedWith(modifierMessage);
        await expect(
            feeManagerContract.connect(jane).updateManager(address)
        ).to.be.revertedWith(modifierMessage);
        await expect(
            feeManagerContract.connect(jane).setDefaultFee(true, 1, 10)
        ).to.be.revertedWith(modifierMessage);
        await expect(
            feeManagerContract.connect(jane).setCampaignFee(address, true, 1, 10)
        ).to.be.revertedWith(modifierMessage);
    })

    it("should verify numerator and denominator ratio", async function () {
        const errorMessage = "FeeManager: fee > 1.0";
        const address = await jane.getAddress();

        await expect(
            feeManagerContract.connect(manager).setDefaultFee(true, 11, 10)
        ).to.be.revertedWith(errorMessage);
        await expect(
            feeManagerContract.connect(manager).setCampaignFee(address, true, 11, 1)
        ).to.be.revertedWith(errorMessage);
    })

    it("should verify denominator is not zero", async function () {
        const errorMessage = "FeeManager: division by zero";
        const address = await jane.getAddress();

        await expect(
            feeManagerContract.connect(manager).setDefaultFee(true, 0, 0)
        ).to.be.revertedWith(errorMessage);
        await expect(
            feeManagerContract.connect(manager).setCampaignFee(address, true, 0, 0)
        ).to.be.revertedWith(errorMessage);
    })
})

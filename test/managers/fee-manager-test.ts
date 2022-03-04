// @ts-ignore
import {ethers} from "hardhat";
import {Contract, Signer} from "ethers";
import * as helpers from "../../util/helpers";
import {expect} from "chai";
import {describe, it} from "mocha";
import { CampaignFeeManager, RevenueFeeManager } from "../../typechain";

describe("Fee Managers test", function () {

    let manager: Signer
    let treasury: Signer
    let jane: Signer
    let feeManagerContract: CampaignFeeManager
    let revenueFeeManagerContract: RevenueFeeManager

    beforeEach(async function () {
        const accounts: Signer[] = await ethers.getSigners();
        manager     = accounts[0];
        treasury    = accounts[1];
        jane        = accounts[2];

        feeManagerContract = await helpers.deployCampaignFeeManager(
            manager,
            await manager.getAddress(),
            await treasury.getAddress()
        ) as CampaignFeeManager;
        revenueFeeManagerContract = await helpers.deployRevenueFeeManager(
            manager,
            await manager.getAddress(),
            await treasury.getAddress()
        ) as RevenueFeeManager;
    })

    it("should verify isManager modifier", async function () {
        const modifierMessage = "!manager";
        const address = await jane.getAddress();

        // CampaignFeeManager
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

        // RevenueFeeManager
        await expect(
            revenueFeeManagerContract.connect(jane).updateTreasury(address)
        ).to.be.revertedWith(modifierMessage);
        await expect(
            revenueFeeManagerContract.connect(jane).updateManager(address)
        ).to.be.revertedWith(modifierMessage);
        await expect(
            revenueFeeManagerContract.connect(jane).setDefaultFee(true, 1, 10)
        ).to.be.revertedWith(modifierMessage);
        await expect(
            revenueFeeManagerContract.connect(jane).setAssetFee(address, true, 1, 10)
        ).to.be.revertedWith(modifierMessage);
        await expect(
            revenueFeeManagerContract.connect(jane).setIssuerFee(address, ethers.constants.AddressZero, [], ethers.constants.AddressZero, true, 1, 10)
        ).to.be.revertedWith(modifierMessage);
    })

    it("should verify numerator and denominator ratio", async function () {
        const errorMessage = "AFeeManager: fee > 1.0";
        const address = await jane.getAddress();

        // CampaignFeeManager
        await expect(
            feeManagerContract.connect(manager).setDefaultFee(true, 11, 10)
        ).to.be.revertedWith(errorMessage);
        await expect(
            feeManagerContract.connect(manager).setCampaignFee(address, true, 11, 1)
        ).to.be.revertedWith(errorMessage);

        // RevenueFeeManager
        await expect(
            revenueFeeManagerContract.connect(manager).setDefaultFee(true, 11, 10)
        ).to.be.revertedWith(errorMessage);
        await expect(
            revenueFeeManagerContract.connect(manager).setAssetFee(address, true, 11, 1)
        ).to.be.revertedWith(errorMessage);
        await expect(
            revenueFeeManagerContract.connect(manager).setIssuerFee(address, ethers.constants.AddressZero, [], ethers.constants.AddressZero, true, 11, 1)
        ).to.be.revertedWith(errorMessage);
    })

    it("should verify denominator is not zero", async function () {
        const errorMessage = "AFeeManager: division by zero";
        const address = await jane.getAddress();

        // CampaignFeeManager
        await expect(
            feeManagerContract.connect(manager).setDefaultFee(true, 0, 0)
        ).to.be.revertedWith(errorMessage);
        await expect(
            feeManagerContract.connect(manager).setCampaignFee(address, true, 0, 0)
        ).to.be.revertedWith(errorMessage);

        // RevenueFeeManager
        await expect(
            revenueFeeManagerContract.connect(manager).setDefaultFee(true, 0, 0)
        ).to.be.revertedWith(errorMessage);
        await expect(
            revenueFeeManagerContract.connect(manager).setAssetFee(address, true, 0, 0)
        ).to.be.revertedWith(errorMessage);
        await expect(
            revenueFeeManagerContract.connect(manager).setIssuerFee(address, ethers.constants.AddressZero, [], ethers.constants.AddressZero, true, 0, 0)
        ).to.be.revertedWith(errorMessage);
    })
})

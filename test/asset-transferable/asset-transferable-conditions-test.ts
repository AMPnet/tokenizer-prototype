// @ts-ignore
import {ethers} from "hardhat";
import {Contract} from "ethers";
import * as helpers from "../../util/helpers";
import {expect} from "chai";
import {it} from "mocha";
import {TestData} from "../TestData"

describe("Asset transferable - test function conditions", function () {

    const testData = new TestData()

    beforeEach(async function () {
        await testData.deploy()
        await testData.deployIssuerAssetTransferableCampaign()
    });

    it(`should verify notLiquidated modifier`, async function () {
        const modifierMessage = "AssetTransferable: Action forbidden, asset liquidated."
        await liquidateAsset()

        await expect(
            testData.asset.connect(testData.assetManager).finalizeSale()
        ).to.be.revertedWith(modifierMessage);
        await expect(
            testData.asset.connect(testData.issuerOwner).approveCampaign(testData.cfManager.address)
        ).to.be.revertedWith(modifierMessage);
        await expect(
            testData.asset.connect(testData.issuerOwner).suspendCampaign(testData.cfManager.address)
        ).to.be.revertedWith(modifierMessage);
        await expect(
            testData.asset.connect(testData.assetManager).liquidate()
        ).to.be.revertedWith(modifierMessage);
        await expect(
            testData.asset.connect(testData.assetManager).snapshot()
        ).to.be.revertedWith(modifierMessage);
        await expect(
            testData.asset.connect(testData.assetManager).migrateApxRegistry(testData.cfManager.address)
        ).to.be.revertedWith(modifierMessage);
    })

    it('should verify ownerOnly modifier', async function () {
        const modifierMessage = "AssetTransferable: Only asset creator can make this action."
        const address = await testData.jane.getAddress()

        await expect(
            testData.asset.connect(testData.alice).approveCampaign(testData.cfManager.address)
        ).to.be.revertedWith(modifierMessage);
        await expect(
            testData.asset.connect(testData.alice).suspendCampaign(testData.cfManager.address)
        ).to.be.revertedWith(modifierMessage);
        await expect(
            testData.asset.connect(testData.alice).changeOwnership(address)
        ).to.be.revertedWith(modifierMessage);
        await expect(
            testData.asset.connect(testData.alice).setInfo("ipfs-hash")
        ).to.be.revertedWith(modifierMessage);
        await expect(
            testData.asset.connect(testData.alice).setWhitelistRequiredForRevenueClaim(false)
        ).to.be.revertedWith(modifierMessage);
        await expect(
            testData.asset.connect(testData.alice).setWhitelistRequiredForLiquidationClaim(false)
        ).to.be.revertedWith(modifierMessage);
        await expect(
            testData.asset.connect(testData.alice).changeOwnership(address)
        ).to.be.revertedWith(modifierMessage);
        await expect(
            testData.asset.connect(testData.alice).setChildChainManager(address)
        ).to.be.revertedWith(modifierMessage);
    })

    it('should verify that only issuer owner can set issuer status', async function () {
        await expect(
            testData.asset.connect(testData.assetManager).setIssuerStatus(false)
        ).to.be.revertedWith("AssetTransferable: Only issuer owner can make this action.")
        const issuerStatus = await testData.asset.connect(testData.issuerOwner).getState()
        const newIssuerStatus = !issuerStatus.assetApprovedByIssuer
        await testData.asset.connect(testData.issuerOwner).setIssuerStatus(newIssuerStatus)
        const setValue = (await testData.asset.connect(testData.issuerOwner).getState()).assetApprovedByIssuer
        expect(setValue).to.be.equal(newIssuerStatus)
    })

    it('should fail to claim liquidation share on not liquidated asset', async function () {
        await expect(
            testData.asset.connect(testData.alice).claimLiquidationShare(await testData.alice.getAddress())
        ).to.be.revertedWith("AssetTransferable: not liquidated")
    })

    it('should fail to claim liquidation share on not whitelisted address', async function () {
        await liquidateAsset()
        await expect(
            testData.asset.connect(testData.alice).claimLiquidationShare(await testData.alice.getAddress())
        ).to.be.revertedWith("AssetTransferable: wallet must be whitelisted before claiming liquidation share.")
    })

    it('should fail to claim zero liquidation funds', async function () {
        await testData.asset.connect(testData.issuerOwner).setWhitelistRequiredForLiquidationClaim(false)
        await liquidateAsset()
        await expect(
            testData.asset.connect(testData.alice).claimLiquidationShare(await testData.alice.getAddress())
        ).to.be.revertedWith("AssetTransferable: no tokens approved for claiming liquidation share")
    })

    it('should verify that only apxRegistry can change apxRegistry address', async function () {
        const newApxRegistry: Contract = await helpers.deployApxRegistry(
            testData.deployer,
            await testData.deployer.getAddress(),
            await testData.assetManager.getAddress(),
            await testData.priceManager.getAddress()
        )
        await testData.apxRegistry.connect(testData.assetManager)
            .registerAsset(testData.asset.address, testData.asset.address, true)
        await newApxRegistry.connect(testData.assetManager)
            .registerAsset(testData.asset.address, testData.asset.address, true)
        await expect(
            testData.asset.connect(testData.issuerOwner).migrateApxRegistry(newApxRegistry.address)
        ).to.be.revertedWith("AssetTransferable: Only apxRegistry can call this function.")
        const oldApxRegistryAddress = (await testData.asset.connect(testData.issuerOwner).getState()).apxRegistry
        expect(oldApxRegistryAddress).to.be.equal(testData.apxRegistry.address)
        await testData.apxRegistry.connect(testData.deployer).migrate(newApxRegistry.address, testData.asset.address)
        const newApxRegistryAddress = (await testData.asset.connect(testData.issuerOwner).getState()).apxRegistry
        expect(newApxRegistryAddress).to.be.equal(newApxRegistry.address)
    })

    it.skip('should fail to finalize not approved campaign', async function () {
        // use smodit to mock owner
        await expect(
            testData.asset.connect(testData.alice).finalizeSale()
        ).to.be.revertedWith("AssetTransferable: Campaign not approved.")
    })

    it.skip('should fail to finalize already finalized campaign', async function () {
        // don't know how to test finalize sale
        await testData.asset.connect(testData.issuerOwner).finalizeSale()
        await expect(
            testData.asset.connect(testData.issuerOwner).finalizeSale()
        ).to.be.revertedWith("AssetTransferable: Campaign not finalized")
    })

    it.skip('should fail to claim zero liquidation funds', async function () {
        // this case is not possible, not sure how to assert that it cannot happen
        await expect(
            testData.asset.connect(testData.alice).claimLiquidationShare(await testData.alice.getAddress())
        ).to.be.revertedWith("AssetTransferable: no liquidation funds to claim")
    })

    async function liquidateAsset() {
        const liquidationFunds = 300000;
        await testData.stablecoin
            .transfer(await testData.issuerOwner.getAddress(), ethers.utils.parseEther(liquidationFunds.toString()));
        await testData.stablecoin.connect(testData.assetManager)
            .approve(testData.asset.address, ethers.utils.parseEther(liquidationFunds.toString()));
        await helpers
            .registerAsset(testData.assetManager, testData.apxRegistry, testData.asset.address, testData.asset.address);
        await helpers.updatePrice(testData.priceManager, testData.apxRegistry, testData.asset, 1, 60);
        await helpers.liquidate(testData.issuerOwner, testData.asset, testData.stablecoin, liquidationFunds);
    }

})

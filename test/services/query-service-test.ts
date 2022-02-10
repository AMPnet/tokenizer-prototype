// @ts-ignore
import * as helpers from "../../util/helpers";
import { expect } from "chai";
import { describe, it } from "mocha";
import { TestData } from "../TestData";
import { ethers } from "ethers";

describe("Query service tests", function () {

    const testData = new TestData();

    it(`will return the correct response for asset balances when
            - no assets owned by the investor
            - asset owned by the investor is the one created through the platform
            - 1 asset owned by the investor is created through the platform while the other one is prexisting`, 
    async function () {

        // state 1: basic setup, empty issuer exists with 0 assets active
        await testData.deploy();
        await testData.deployIssuer();
        const issuerOwnerAddress = await testData.issuerOwner.getAddress();
        const aliceAddress = await testData.alice.getAddress();
        
        const assetBalancesResponse1 = await queryIssuerForAssetBalances(aliceAddress);
        expect(assetBalancesResponse1.length).to.be.equal(0);

        // state 2: there's 1 tranferable asset in existence (creted by ampnet) but investor balance is still 0
        const assetTransferableName = "Test Asset";
        const assetTransferableSymbol = "TA";
        const assetTransferableInfoHash = "info-hash";
        const assetTransferableTotalSupply = 10000000;
        const assetTransferableTotalSupplyWei = await ethers.utils.parseEther(assetTransferableTotalSupply.toString());
        const assetTransferable = await helpers.createAssetTransferable(
            issuerOwnerAddress,
            testData.issuer,
            "mapped-name",
            assetTransferableTotalSupply,
            false ,false,
            assetTransferableName,
            assetTransferableSymbol,
            assetTransferableInfoHash,
            testData.assetTransferableFactory,
            testData.nameRegistry,
            testData.apxRegistry
        );
        const assetBalancesResponse2 = await queryIssuerForAssetBalances(aliceAddress);
        expect(assetBalancesResponse2.length).to.be.equal(0);

        // state 3: alice obtains some of the tokens of the asset created through the platform
        const aliceOwnedTokens = 1000;
        await assetTransferable.connect(testData.issuerOwner).transfer(aliceAddress, aliceOwnedTokens);
        const assetBalancesResponse3 = await queryIssuerForAssetBalances(aliceAddress);
        expect(assetBalancesResponse3.length).to.be.equal(1);
        expect(assetBalancesResponse3[0].contractAddress).to.be.equal(assetTransferable.address);
        expect(assetBalancesResponse3[0].decimals).to.be.equal(18);
        expect(assetBalancesResponse3[0].name).to.be.equal(assetTransferableName);
        expect(assetBalancesResponse3[0].symbol).to.be.equal(assetTransferableSymbol);
        expect(assetBalancesResponse3[0].balance.toNumber()).to.be.equal(aliceOwnedTokens);
        expect(assetBalancesResponse3[0].assetCommonState.flavor).to.exist;
        expect(assetBalancesResponse3[0].assetCommonState.version).to.exist;
        expect(assetBalancesResponse3[0].assetCommonState.contractAddress).to.be.equal(assetTransferable.address);
        expect(assetBalancesResponse3[0].assetCommonState.owner).to.be.equal(issuerOwnerAddress);
        expect(assetBalancesResponse3[0].assetCommonState.info).to.be.equal(assetTransferableInfoHash);
        expect(assetBalancesResponse3[0].assetCommonState.name).to.be.equal(assetTransferableName);
        expect(assetBalancesResponse3[0].assetCommonState.symbol).to.be.equal(assetTransferableSymbol);
        expect(assetBalancesResponse3[0].assetCommonState.totalSupply).to.be.equal(assetTransferableTotalSupplyWei);
        expect(assetBalancesResponse3[0].assetCommonState.decimals).to.be.equal(18);
        expect(assetBalancesResponse3[0].assetCommonState.issuer).to.be.equal(testData.issuer.address);
    });

    async function queryIssuerForAssetBalances(investor: string) {
        return helpers.queryIssuerForAssetBalances(
            testData.queryService,
            testData.issuer,
            investor,
            [
                testData.assetFactory.address,
                testData.assetSimpleFactory.address,
                testData.assetTransferableFactory.address
            ],
            [
                testData.cfManagerFactory.address,
                testData.cfManagerVestingFactory.address
            ]
        );
    }

})

// @ts-ignore
import * as helpers from "../../util/helpers";
import { expect } from "chai";
import { describe, it } from "mocha";
import { TestData } from "../TestData";
import { ethers, BigNumber } from "ethers";

describe("Query service tests", function () {

    const testData = new TestData();

    beforeEach(async function() {
        await testData.deploy();
        await testData.deployIssuer();
    });

    it(`will return the correct response for asset balances when
            - no assets owned by the investor
            - asset owned by the investor is the one created through the platform
            - 1 asset owned by the investor is created through the platform while the other one is prexisting`, 
    async function () {

        // state 1: basic setup, empty issuer exists with 0 assets active
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


    it(`will return the correct response for getERC20AssetsForIssuer`, async function () {
        const issuerOwnerAddress = await testData.issuerOwner.getAddress();

        const emptyIssuerResponse = await testData.queryService.getERC20AssetsForIssuer(
            testData.issuer.address,
            [
                testData.assetFactory.address,
                testData.assetTransferableFactory.address,
                testData.assetSimpleFactory.address
            ], [ ]
        );
        expect(emptyIssuerResponse.length).to.be.equal(0);

        const assetBasicName = "Test Asset Basic";
        const assetBasicSymbol = "TAB";
        const assetBasicInfoHash = "info-hash-tab";
        const assetBasicTotalSupply = 10000000;
        const assetBasicTotalSupplyWei = await ethers.utils.parseEther(assetBasicTotalSupply.toString());
        const assetBasic = await helpers.createAsset(
            issuerOwnerAddress,
            testData.issuer,
            "mapped-name-1",
            assetBasicTotalSupply,
            false, false ,false,
            assetBasicName,
            assetBasicSymbol,
            assetBasicInfoHash,
            testData.assetFactory,
            testData.nameRegistry,
            testData.apxRegistry
        );

        const assetTransferableName = "Test Asset Transferable";
        const assetTransferableSymbol = "TAT";
        const assetTransferableInfoHash = "info-hash-tat";
        const assetTransferableTotalSupply = 10000000;
        const assetTransferableTotalSupplyWei = await ethers.utils.parseEther(assetTransferableTotalSupply.toString());
        const assetTransferable = await helpers.createAssetTransferable(
            issuerOwnerAddress,
            testData.issuer,
            "mapped-name-2",
            assetTransferableTotalSupply,
            false ,false,
            assetTransferableName,
            assetTransferableSymbol,
            assetTransferableInfoHash,
            testData.assetTransferableFactory,
            testData.nameRegistry,
            testData.apxRegistry
        );

        const assetSimpleName = "Test Asset Simple";
        const assetSimpleSymbol = "TAS";
        const assetSimpleInfoHash = "info-hash-tas";
        const assetSimpleTotalSupply = 10000000;
        const assetSimpleTotalSupplyWei = await ethers.utils.parseEther(assetSimpleTotalSupply.toString());
        const assetSimple = await helpers.createAssetSimple(
            issuerOwnerAddress,
            testData.issuer,
            "mapped-name-3",
            assetSimpleTotalSupply,
            assetSimpleName,
            assetSimpleSymbol,
            assetSimpleInfoHash,
            testData.assetSimpleFactory,
            testData.nameRegistry
        );

        const assetStatesResponse = await testData.queryService.getERC20AssetsForIssuer(
            testData.issuer.address,
            [
                testData.assetFactory.address,
                testData.assetTransferableFactory.address,
                testData.assetSimpleFactory.address
            ], [ ]
        );

        expect(assetStatesResponse.length).to.be.equal(3);
        
        const basic = assetStatesResponse.find(response => response.contractAddress == assetBasic.address);
        expect(basic.decimals).to.be.equal(await assetBasic.decimals());
        expect(basic.name).to.be.equal(await assetBasic.name());
        expect(basic.symbol).to.be.equal(await assetBasic.symbol());
        expect(basic.commonState.flavor).to.be.equal(await assetBasic.flavor());
        expect(basic.commonState.version).to.be.equal(await assetBasic.version());
        expect(basic.commonState.contractAddress).to.be.equal(assetBasic.address);
        expect(basic.commonState.owner).to.be.equal(issuerOwnerAddress);
        expect(basic.commonState.info).to.be.equal(assetBasicInfoHash);
        expect(basic.commonState.name).to.be.equal(assetBasicName);
        expect(basic.commonState.symbol).to.be.equal(assetBasicSymbol);
        expect(basic.commonState.totalSupply).to.be.equal(assetBasicTotalSupplyWei);
        expect(basic.commonState.decimals).to.be.equal(await assetBasic.decimals());
        expect(basic.commonState.issuer).to.be.equal(testData.issuer.address);

        const transferable = assetStatesResponse.find(response => response.contractAddress == assetTransferable.address);
        expect(transferable.decimals).to.be.equal(await assetTransferable.decimals());
        expect(transferable.name).to.be.equal(await assetTransferable.name());
        expect(transferable.symbol).to.be.equal(await assetTransferable.symbol());
        expect(transferable.commonState.flavor).to.be.equal(await assetTransferable.flavor());
        expect(transferable.commonState.version).to.be.equal(await assetTransferable.version());
        expect(transferable.commonState.contractAddress).to.be.equal(assetTransferable.address);
        expect(transferable.commonState.owner).to.be.equal(issuerOwnerAddress);
        expect(transferable.commonState.info).to.be.equal(assetTransferableInfoHash);
        expect(transferable.commonState.name).to.be.equal(assetTransferableName);
        expect(transferable.commonState.symbol).to.be.equal(assetTransferableSymbol);
        expect(transferable.commonState.totalSupply).to.be.equal(assetTransferableTotalSupplyWei);
        expect(transferable.commonState.decimals).to.be.equal(await assetTransferable.decimals());
        expect(transferable.commonState.issuer).to.be.equal(testData.issuer.address);

        const simple = assetStatesResponse.find(response => response.contractAddress == assetSimple.address);
        expect(simple.decimals).to.be.equal(await assetSimple.decimals());
        expect(simple.name).to.be.equal(await assetSimple.name());
        expect(simple.symbol).to.be.equal(await assetSimple.symbol());
        expect(simple.commonState.flavor).to.be.equal(await assetSimple.flavor());
        expect(simple.commonState.version).to.be.equal(await assetSimple.version());
        expect(simple.commonState.contractAddress).to.be.equal(assetSimple.address);
        expect(simple.commonState.owner).to.be.equal(issuerOwnerAddress);
        expect(simple.commonState.info).to.be.equal(assetSimpleInfoHash);
        expect(simple.commonState.name).to.be.equal(assetSimpleName);
        expect(simple.commonState.symbol).to.be.equal(assetSimpleSymbol);
        expect(simple.commonState.totalSupply).to.be.equal(assetSimpleTotalSupplyWei);
        expect(simple.commonState.decimals).to.be.equal(await assetSimple.decimals());
        expect(simple.commonState.issuer).to.be.equal(testData.issuer.address);
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

    interface ERC20AssetCommonState {
        contractAddress: string;
        decimals: BigNumber;
        name: string;
        symbol: string;
        commonState: {
            flavor: string;
            version: string;
            contractAddress: string;
            owner: string;
            info: string;
            name: string;
            symbol: string;
            totalSupply: BigNumber;
            decimals: BigNumber;
            issuer: string;
        }
    }

})

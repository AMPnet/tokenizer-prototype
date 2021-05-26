import { ethers } from "hardhat";
import { ContractFactory, Signer, Contract } from "ethers";
import { expect } from "chai";
import { smockit, smoddit } from "@eth-optimism/smock";

import { Errors } from "./errors";
import { Events } from "./events";
import { mapToObject } from "./util";

describe("Asset", function() {

    let asset: Contract;

    let deployerWallet: Signer;
    let deployerAddress: String;

    let wallet1: Signer;
    let address1: String;
    let wallet2: Signer;
    let address2: String;
    let wallet3: Signer;
    let address3: String;

    const ADDRESS_ZERO = ethers.constants.AddressZero; 

    const ASSET_NAME = "Kick Asset Co.";
    const ASSET_TICKER = "KCKASS";
    const ASSET_CATEGORY_ID = 1122;
    const ASSET_IPFS_HASH = "ipfs-hash";
    const ASSET_SHARES = ethers.utils.parseEther("100");
    
    enum AssetState { CREATION = 0, TOKENIZED = 1 };

    async function deployAsset(state: AssetState, tokenizerAddress: String = ADDRESS_ZERO) {
        const Asset: ContractFactory = await ethers.getContractFactory("Asset");
        asset = await Asset.deploy(
            deployerAddress,
            tokenizerAddress,
            state,
            ASSET_CATEGORY_ID,
            ASSET_SHARES,
            ASSET_NAME,
            ASSET_TICKER
        );
    }

    async function generateIssuerMock(approvedWallets: Map<String, Boolean> = new Map()) {
        if (approvedWallets.size === 0) {
            const Issuer: ContractFactory = await ethers.getContractFactory("Issuer");
            const issuer = await Issuer.deploy(ADDRESS_ZERO, ADDRESS_ZERO, ADDRESS_ZERO);
            const issuerMock = await smockit(issuer);
            issuerMock.smocked.isWalletApproved.will.return.with(true);
            return issuerMock;
        } else {
            const IssuerModifiable = await smoddit("Issuer");
            const issuerModifiable = await IssuerModifiable.deploy(ADDRESS_ZERO, ADDRESS_ZERO, ADDRESS_ZERO);
            const approvedWalletsObj = mapToObject(approvedWallets);
            await issuerModifiable.smodify.put({
                approvedWallets: approvedWalletsObj
            });
            return issuerModifiable;
        }
    }

    before(async function () {
        [deployerWallet, wallet1, wallet2, wallet3] = await ethers.getSigners();
        deployerAddress = await deployerWallet.getAddress();
        address1 = await wallet1.getAddress();
        address2 = await wallet2.getAddress();
        address3 = await wallet3.getAddress();
    });

    describe("Deployment", function () {
        beforeEach(async function () {
            await deployAsset(AssetState.TOKENIZED);
        })

        it("should deploy Asset with given params and set Asset Info", async function () {
            expect(await asset.creator()).to.be.equal(deployerAddress);
            expect(await asset.issuer()).to.be.equal(ADDRESS_ZERO);
            expect(await asset.categoryId()).to.be.equal(ASSET_CATEGORY_ID);
            expect(await asset.state()).to.be.equal(AssetState.TOKENIZED);
            expect(await asset.totalShares()).to.be.equal(ASSET_SHARES);
            expect(await asset.balanceOf(deployerAddress)).to.be.equal(ASSET_SHARES);
        });

        it("can only update Asset Info if the caller is Asset creator", async function() {
            await asset.setInfo(ASSET_IPFS_HASH);
            expect(await asset.info()).to.be.equal(ASSET_IPFS_HASH);

            await expect(asset.connect(wallet1).setInfo("new info"))
                .to.be.revertedWith(Errors.ONLY_ASSET_CREATOR_ALLOWED);
        });

        it("can only update Asset Creator if the caller is Asset creator", async function() {            
            await asset.setCreator(address1);
            expect(await asset.creator()).to.be.equal(address1);

            await expect(asset.setCreator(ADDRESS_ZERO))
                .to.be.revertedWith(Errors.ONLY_ASSET_CREATOR_ALLOWED);
        });
    });

    describe("ERC20 Snapshots", function () {

        it("should be able to take few snapshots and check balances at any point", async function () {
            const SNAPSHOT_ID = 1;

            const Snapshot = {
                deployerBalance: ASSET_SHARES,
                address1Balance: ethers.constants.Zero
            }
            
            const issuer = await generateIssuerMock(new Map<String, Boolean>([
                [deployerAddress, true],
                [address1, true]
            ]));
            await deployAsset(AssetState.TOKENIZED, issuer.address);

            expect(await asset.balanceOf(deployerAddress)).to.be.equal(Snapshot.deployerBalance);
            expect(await asset.balanceOf(address1)).to.be.equal(Snapshot.address1Balance);
            await expect(asset.snapshot())
                .to.emit(asset, Events.SNAPSHOT)
                .withArgs(SNAPSHOT_ID);
            await asset.transfer(address1, ASSET_SHARES.div(2));

            expect(await asset.balanceOfAt(deployerAddress, SNAPSHOT_ID)).to.be.equal(Snapshot.deployerBalance);
            expect(await asset.balanceOfAt(address1, SNAPSHOT_ID)).to.be.equal(Snapshot.address1Balance);
            expect(await asset.balanceOf(deployerAddress)).to.be.equal(ASSET_SHARES.div(2));
            expect(await asset.balanceOf(address1)).to.be.equal(ASSET_SHARES.div(2));
        });

    });

    describe("State: Creation", function () {
        
    });

    describe("State: Tokenized", function () {

    });
});

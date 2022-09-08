// @ts-ignore
import { ethers } from "hardhat";
import { Signer, Wallet } from "ethers";
import * as helpers from "../../util/helpers";
import { expect } from "chai";
import { describe, it } from "mocha";
import { USDC, SupplyChainManager } from "../../typechain";

describe("Supply chain manager test", function () {

    enum Role {
        PRODUCTION = 1,
        PACKING = 2,
        SHIPPING = 3,
        BUYER = 4
    }

    let supplyChainManager: SupplyChainManager;
    let usdc: USDC;
    let manager: Signer;
    let managerAddress: string;
    let manufacturer: Signer;
    let manufacturerAdddress: string;
    let producer: Signer;
    let producerAddress: string;
    let packager: Signer;
    let packagerAddress: string;
    let shipper: Signer;
    let shipperAddress: string;
    let receiver: Signer;
    let receiverAddress: string;

    beforeEach(async function () {
        const accounts: Signer[] = await ethers.getSigners();
        manager         = accounts[0];
        manufacturer    = accounts[1];
        producer        = accounts[2];
        packager        = accounts[3];
        shipper         = accounts[4];
        receiver        = accounts[5];
        managerAddress          = await manager.getAddress();
        manufacturerAdddress    = await manufacturer.getAddress();
        producerAddress         = await producer.getAddress();
        packagerAddress         = await packager.getAddress();
        shipperAddress          = await shipper.getAddress();
        receiverAddress         = await receiver.getAddress();

        let supplyChainManagerFactory = await ethers.getContractFactory("SupplyChainManager", manager);
        usdc = (await helpers.deployStablecoin(manager, 1000, 18)) as USDC;
        supplyChainManager = await supplyChainManagerFactory.connect(manager).deploy(
            managerAddress,
            manufacturerAdddress,
            usdc.address
        );
    });

    it('should be able to run one full product lifetime flow (production to shipping)', async () => {
        
        // MANAGER CAN ADD USERS
        await supplyChainManager.addUser(
            producerAddress,
            "main producer",
            Role.PRODUCTION
        );
        await supplyChainManager.addUser(
            packagerAddress,
            "main packager",
            Role.PACKING
        );
        await supplyChainManager.addUser(
            shipperAddress,
            "dhl",
            Role.SHIPPING
        );
        await supplyChainManager.addUser(
            receiverAddress,
            "buying customer",
            Role.BUYER
        );

        // SETUP DEACTIVATED USER
        const deactivated = Wallet.createRandom().connect(ethers.provider);
        const deactivatedAddress = await deactivated.getAddress();
        await supplyChainManager.addUser(
            deactivatedAddress,
            "deactivated address",
            Role.BUYER
        );
        await supplyChainManager.updateUserStatus(
            deactivatedAddress,
            false
        );
        await manager.sendTransaction({
            to: deactivatedAddress,
            value: ethers.utils.parseEther("1.0")
        });

        // SETUP UNREGISTERED USER

        const unregistered = Wallet.createRandom().connect(ethers.provider);
        const unregisteredAddress = await unregistered.getAddress();
        await manager.sendTransaction({
            to: unregisteredAddress,
            value: ethers.utils.parseEther("1.0")
        });

        // ALREADY EXISTING USERS CAN NOT BE ADDED
        const failedRepeatedAddUserTx = supplyChainManager.addUser(
            producerAddress,
            "random info",
            Role.PRODUCTION
        );
        await expect(failedRepeatedAddUserTx).to.be.revertedWith("User already exists!");

        // OTHERS CAN NOT ADD USERS
        const randomWallet = Wallet.createRandom();
        const randomWalletAddress = await randomWallet.getAddress();
        const failedAddUserTx = supplyChainManager.connect(packager).addUser(
            randomWalletAddress,
            "random info",
            Role.PACKING
        );
        await expect(failedAddUserTx).to.be.revertedWith("Not manager!");
        
        // CAN NOT UPDATE NON-EXISTING USER
        const failedUpdateNonExistingUserTx = supplyChainManager.updateUserStatus(
            randomWalletAddress,
            true
        );
        await expect(failedUpdateNonExistingUserTx).to.be.revertedWith("User does not exist");

        // OTHERS CAN NOT UPDATE USERS
        const failedForbiddenUpdateUserTx = supplyChainManager.connect(packager).updateUserStatus(
            shipperAddress,
            false
        );
        await expect(failedForbiddenUpdateUserTx).to.be.revertedWith("Not manager!");
        
        // PRODUCE PRODUCT
        const barcode = "123abc456def";
        const price = 100;
        await supplyChainManager.connect(producer).setProduced(
            barcode,
            price,
            "product description",
            "action description"
        );
        await expect(
            supplyChainManager.connect(producer).setProduced(
                barcode,
                price,
                "product description",
                "action description"
            )
        ).to.be.revertedWith("Barcode already exists!");
        await expect(
            supplyChainManager.connect(producer).setProduced(
                "",
                price,
                "product description",
                "action description"
            )
        ).to.be.revertedWith("Barcode is empty!");
        await expect(
            supplyChainManager.connect(unregistered).setProduced(barcode, price, "", "")
        ).to.be.revertedWith("User not registered!");
        await expect(
            supplyChainManager.connect(deactivated).setProduced(barcode, price, "", "")
        ).to.be.revertedWith("User deactivated!");
        await expect(
            supplyChainManager.connect(packager).setProduced(barcode, price, "", "")
        ).to.be.revertedWith("User missing role!");

        // PACK PRODUCT
        await supplyChainManager.connect(packager).setPacked(0, "pack action description");
        await expect(
            supplyChainManager.connect(unregistered).setPacked(0, "pack action description")
        ).to.be.revertedWith("User not registered!");
        await expect(
            supplyChainManager.connect(deactivated).setPacked(0, "pack action description")
        ).to.be.revertedWith("User deactivated!");
        await expect(
            supplyChainManager.connect(producer).setPacked(0, "pack action description")
        ).to.be.revertedWith("User missing role!");
        await expect(
            supplyChainManager.connect(packager).setPacked(0, "pack action description")
        ).to.be.revertedWith("Invalid product state!");

        // SHIP PRODUCT
        await supplyChainManager.connect(shipper).setShipped(0, "ship action description");
        await expect(
            supplyChainManager.connect(unregistered).setShipped(0, "ship action description")
        ).to.be.revertedWith("User not registered!");
        await expect(
            supplyChainManager.connect(deactivated).setShipped(0, "ship action description")
        ).to.be.revertedWith("User deactivated!");
        await expect(
            supplyChainManager.connect(producer).setShipped(0, "ship action description")
        ).to.be.revertedWith("User missing role!");
        await expect(
            supplyChainManager.connect(shipper).setShipped(0, "ship action description")
        ).to.be.revertedWith("Invalid product state!");

        // FAILED RECEIVE PRODUCT (receiver did not pay for item)
        await expect(
            supplyChainManager.connect(receiver).setReceived(0, "receive action description")
        ).to.be.revertedWith("ERC20: transfer amount exceeds balance");

        // RECEIVER PAYS FOR PRODUCT
        await usdc.transfer(supplyChainManager.address, price);
        await supplyChainManager.connect(receiver).setReceived(0, "receive action description");
        expect(await usdc.balanceOf(manufacturerAdddress)).to.be.equal(price);
        expect(await usdc.balanceOf(supplyChainManager.address)).to.be.equal(0);

        await expect(
            supplyChainManager.connect(unregistered).setReceived(0, "receive action description")
        ).to.be.revertedWith("User not registered!");
        await expect(
            supplyChainManager.connect(deactivated).setReceived(0, "receive action description")
        ).to.be.revertedWith("User deactivated!");
        await expect(
            supplyChainManager.connect(producer).setReceived(0, "receive action description")
        ).to.be.revertedWith("User missing role!");
        await expect(
            supplyChainManager.connect(receiver).setReceived(0, "receive action description")
        ).to.be.revertedWith("Invalid product state!");

        // TEST QUERY METHODS
        console.log(
            "getUsers()",
            await supplyChainManager.getUsers()
        );

        console.log(
            "getProducts()",
            await supplyChainManager.getProducts()
        );
        
        console.log(
            "getUserHistory(producer)",
            await supplyChainManager.getUserHistory(producerAddress)
        );

        console.log(
            "getUserHistory(packager)",
            await supplyChainManager.getUserHistory(packagerAddress)
        );

        console.log(
            "getUserHistory(shipper)",
            await supplyChainManager.getUserHistory(shipperAddress)
        );

        console.log(
            "getUserHistory(receiver)",
            await supplyChainManager.getUserHistory(receiverAddress)
        );
        
        console.log(
            "getProductHistory(product)",
            await supplyChainManager.getProductHistory(barcode)
        );
    });

});

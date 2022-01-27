// @ts-ignore
import { ethers } from "hardhat";
import { Signer } from "ethers";
import { expect } from "chai";
import { describe, it } from "mocha";
import { MerkleTreePathValidator } from "../../typechain";

describe("Merkle tree path validator test", function () {

    //////// CONTRACTS ////////
    let merkleTreePathValidatorService: MerkleTreePathValidator;

    beforeEach(async function () {
        const accounts: Signer[] = await ethers.getSigners();
        const factory = await ethers.getContractFactory("MerkleTreePathValidator", accounts[0]);
        const contract = await factory.deploy();

        merkleTreePathValidatorService = contract as MerkleTreePathValidator;
    });

    it('should correctly determine when node is contained in Merkle tree', async function() {
        // Merkle tree with root hash 0x9a698aa257c1a199678525bcaa8b88e5a643cc1dc6e014523f64e26352b3411b
        // was generated for the following nodes:
        //
        // wallet address -> balance
        //
        // 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266 -> 1000
        // 0x70997970C51812dc3A010C7d01b50e0d17dc79C8 -> 2000
        // 0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC -> 3000
        // 0x90F79bf6EB2c4f870365E785982E1f101E93b906 -> 4000
        // 0x15d34AAf54267DB7D7c367839AAf71A00a2C6A65 -> 5000
        // 0x9965507D1a55bcC2695C58ba16FB37d819B0A4dc -> 6000
        // 0x976EA74026E726554dB657fA54763abd0C3a0aa9 -> 7000

        let account1Result = await merkleTreePathValidatorService.containsNode(
            "0x9a698aa257c1a199678525bcaa8b88e5a643cc1dc6e014523f64e26352b3411b",
            "0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266",
            1000,
            [
                {"siblingHash": "0x0000000000000000000000000000000000000000000000000000000000000000", "isLeft": false},
                {"siblingHash": "0x6d682c19382cfb9fba0d41ecb3fb58412d6af48fcd7e6f0e4c2ecf0ed9218256", "isLeft": true},
                {"siblingHash": "0xfebca01c36ea33cc6c1590186c766592b5bdd3150fa46cb1cf094ff176e023c9", "isLeft": true}
            ]
        );
        expect(account1Result).to.be.equal(true);

        let account2Result = await merkleTreePathValidatorService.containsNode(
            "0x9a698aa257c1a199678525bcaa8b88e5a643cc1dc6e014523f64e26352b3411b",
            "0x70997970C51812dc3A010C7d01b50e0d17dc79C8",
            2000,
            [
                {"siblingHash": "0x752e282b9447f0caa9c85222d24f2cbfe6cf08d277349cca7a7ba42cfaac0c2f", "isLeft": false},
                {"siblingHash": "0x4626b33e8271b36404b811ac2538f8f393ec9ce4116f077dbecb710122c0a0d8", "isLeft": true},
                {"siblingHash": "0x94e3fca9840a80bbd479d6165edfcaf83c7c9795d01bad65d7e3d21b04bd4cee", "isLeft": false}
            ]
        );
        expect(account2Result).to.be.equal(true);

        let account3Result = await merkleTreePathValidatorService.containsNode(
            "0x9a698aa257c1a199678525bcaa8b88e5a643cc1dc6e014523f64e26352b3411b",
            "0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC",
            3000,
            [
                {"siblingHash": "0x0e7e48f58c5bd144faf53a9046591ec912af78cd6d8f0c1d8a41ab519e9b596f", "isLeft": true},
                {"siblingHash": "0x2ff8f2dbc17190d9e3708fa40ff180da9f68460d101a4d23fdc3c64f16e58c76", "isLeft": false},
                {"siblingHash": "0x94e3fca9840a80bbd479d6165edfcaf83c7c9795d01bad65d7e3d21b04bd4cee", "isLeft": false}
            ]
        );
        expect(account3Result).to.be.equal(true);

        let account4Result = await merkleTreePathValidatorService.containsNode(
            "0x9a698aa257c1a199678525bcaa8b88e5a643cc1dc6e014523f64e26352b3411b",
            "0x90F79bf6EB2c4f870365E785982E1f101E93b906",
            4000,
            [
                {"siblingHash": "0x17eded8ad02538d86cb3968c49f57bf8f6610522689115d97799542e598a1de6", "isLeft": true},
                {"siblingHash": "0x4626b33e8271b36404b811ac2538f8f393ec9ce4116f077dbecb710122c0a0d8", "isLeft": true},
                {"siblingHash": "0x94e3fca9840a80bbd479d6165edfcaf83c7c9795d01bad65d7e3d21b04bd4cee", "isLeft": false}
            ]
        );
        expect(account4Result).to.be.equal(true);

        let account5Result = await merkleTreePathValidatorService.containsNode(
            "0x9a698aa257c1a199678525bcaa8b88e5a643cc1dc6e014523f64e26352b3411b",
            "0x15d34AAf54267DB7D7c367839AAf71A00a2C6A65",
            5000,
            [
                {"siblingHash": "0x1fbd400bd5326802cf3e4f204a758a6262b480feb5d24a2331efb1eb1fa5f6e6", "isLeft": false},
                {"siblingHash": "0x2ff8f2dbc17190d9e3708fa40ff180da9f68460d101a4d23fdc3c64f16e58c76", "isLeft": false},
                {"siblingHash": "0x94e3fca9840a80bbd479d6165edfcaf83c7c9795d01bad65d7e3d21b04bd4cee", "isLeft": false}
            ]
        );
        expect(account5Result).to.be.equal(true);

        let account6Result = await merkleTreePathValidatorService.containsNode(
            "0x9a698aa257c1a199678525bcaa8b88e5a643cc1dc6e014523f64e26352b3411b",
            "0x9965507D1a55bcC2695C58ba16FB37d819B0A4dc",
            6000,
            [
                {"siblingHash": "0xdb71ba83cb8880568ff33cb3b1dfc1f4fa249740bef22dbc9f0238fef4303152", "isLeft": true},
                {"siblingHash": "0xb898fa82d49c05ad38b5b03121f95393f6d638af090b8bc856af6a5ade313d78", "isLeft": false},
                {"siblingHash": "0xfebca01c36ea33cc6c1590186c766592b5bdd3150fa46cb1cf094ff176e023c9", "isLeft": true}
            ]
        );
        expect(account6Result).to.be.equal(true);

        let account7Result = await merkleTreePathValidatorService.containsNode(
            "0x9a698aa257c1a199678525bcaa8b88e5a643cc1dc6e014523f64e26352b3411b",
            "0x976EA74026E726554dB657fA54763abd0C3a0aa9",
            7000,
            [
                {"siblingHash": "0xb579f5c13eeb27b66f36ee9352993cf06592fae6d57ddaab8173b514d816bca6", "isLeft": false},
                {"siblingHash": "0xb898fa82d49c05ad38b5b03121f95393f6d638af090b8bc856af6a5ade313d78", "isLeft": false},
                {"siblingHash": "0xfebca01c36ea33cc6c1590186c766592b5bdd3150fa46cb1cf094ff176e023c9", "isLeft": true}
            ]
        );
        expect(account7Result).to.be.equal(true);
    });

    it('should correctly determine when node is not contained in Merkle tree', async function() {
        // Merkle tree with root hash 0x9a698aa257c1a199678525bcaa8b88e5a643cc1dc6e014523f64e26352b3411b
        // was generated for the following nodes:
        //
        // wallet address -> balance
        //
        // 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266 -> 1000
        // 0x70997970C51812dc3A010C7d01b50e0d17dc79C8 -> 2000
        // 0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC -> 3000
        // 0x90F79bf6EB2c4f870365E785982E1f101E93b906 -> 4000
        // 0x15d34AAf54267DB7D7c367839AAf71A00a2C6A65 -> 5000
        // 0x9965507D1a55bcC2695C58ba16FB37d819B0A4dc -> 6000
        // 0x976EA74026E726554dB657fA54763abd0C3a0aa9 -> 7000

        // here users provide fake account balances

        let account1Result = await merkleTreePathValidatorService.containsNode(
            "0x9a698aa257c1a199678525bcaa8b88e5a643cc1dc6e014523f64e26352b3411b",
            "0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266",
            1500,
            [
                {"siblingHash": "0x0000000000000000000000000000000000000000000000000000000000000000", "isLeft": false},
                {"siblingHash": "0x6d682c19382cfb9fba0d41ecb3fb58412d6af48fcd7e6f0e4c2ecf0ed9218256", "isLeft": true},
                {"siblingHash": "0xfebca01c36ea33cc6c1590186c766592b5bdd3150fa46cb1cf094ff176e023c9", "isLeft": true}
            ]
        );
        expect(account1Result).to.be.equal(false);

        let account2Result = await merkleTreePathValidatorService.containsNode(
            "0x9a698aa257c1a199678525bcaa8b88e5a643cc1dc6e014523f64e26352b3411b",
            "0x70997970C51812dc3A010C7d01b50e0d17dc79C8",
            2500,
            [
                {"siblingHash": "0x752e282b9447f0caa9c85222d24f2cbfe6cf08d277349cca7a7ba42cfaac0c2f", "isLeft": false},
                {"siblingHash": "0x4626b33e8271b36404b811ac2538f8f393ec9ce4116f077dbecb710122c0a0d8", "isLeft": true},
                {"siblingHash": "0x94e3fca9840a80bbd479d6165edfcaf83c7c9795d01bad65d7e3d21b04bd4cee", "isLeft": false}
            ]
        );
        expect(account2Result).to.be.equal(false);

        let account3Result = await merkleTreePathValidatorService.containsNode(
            "0x9a698aa257c1a199678525bcaa8b88e5a643cc1dc6e014523f64e26352b3411b",
            "0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC",
            3500,
            [
                {"siblingHash": "0x0e7e48f58c5bd144faf53a9046591ec912af78cd6d8f0c1d8a41ab519e9b596f", "isLeft": true},
                {"siblingHash": "0x2ff8f2dbc17190d9e3708fa40ff180da9f68460d101a4d23fdc3c64f16e58c76", "isLeft": false},
                {"siblingHash": "0x94e3fca9840a80bbd479d6165edfcaf83c7c9795d01bad65d7e3d21b04bd4cee", "isLeft": false}
            ]
        );
        expect(account3Result).to.be.equal(false);

        let account4Result = await merkleTreePathValidatorService.containsNode(
            "0x9a698aa257c1a199678525bcaa8b88e5a643cc1dc6e014523f64e26352b3411b",
            "0x90F79bf6EB2c4f870365E785982E1f101E93b906",
            4500,
            [
                {"siblingHash": "0x17eded8ad02538d86cb3968c49f57bf8f6610522689115d97799542e598a1de6", "isLeft": true},
                {"siblingHash": "0x4626b33e8271b36404b811ac2538f8f393ec9ce4116f077dbecb710122c0a0d8", "isLeft": true},
                {"siblingHash": "0x94e3fca9840a80bbd479d6165edfcaf83c7c9795d01bad65d7e3d21b04bd4cee", "isLeft": false}
            ]
        );
        expect(account4Result).to.be.equal(false);

        let account5Result = await merkleTreePathValidatorService.containsNode(
            "0x9a698aa257c1a199678525bcaa8b88e5a643cc1dc6e014523f64e26352b3411b",
            "0x15d34AAf54267DB7D7c367839AAf71A00a2C6A65",
            5500,
            [
                {"siblingHash": "0x1fbd400bd5326802cf3e4f204a758a6262b480feb5d24a2331efb1eb1fa5f6e6", "isLeft": false},
                {"siblingHash": "0x2ff8f2dbc17190d9e3708fa40ff180da9f68460d101a4d23fdc3c64f16e58c76", "isLeft": false},
                {"siblingHash": "0x94e3fca9840a80bbd479d6165edfcaf83c7c9795d01bad65d7e3d21b04bd4cee", "isLeft": false}
            ]
        );
        expect(account5Result).to.be.equal(false);

        let account6Result = await merkleTreePathValidatorService.containsNode(
            "0x9a698aa257c1a199678525bcaa8b88e5a643cc1dc6e014523f64e26352b3411b",
            "0x9965507D1a55bcC2695C58ba16FB37d819B0A4dc",
            6500,
            [
                {"siblingHash": "0xdb71ba83cb8880568ff33cb3b1dfc1f4fa249740bef22dbc9f0238fef4303152", "isLeft": true},
                {"siblingHash": "0xb898fa82d49c05ad38b5b03121f95393f6d638af090b8bc856af6a5ade313d78", "isLeft": false},
                {"siblingHash": "0xfebca01c36ea33cc6c1590186c766592b5bdd3150fa46cb1cf094ff176e023c9", "isLeft": true}
            ]
        );
        expect(account6Result).to.be.equal(false);

        let account7Result = await merkleTreePathValidatorService.containsNode(
            "0x9a698aa257c1a199678525bcaa8b88e5a643cc1dc6e014523f64e26352b3411b",
            "0x976EA74026E726554dB657fA54763abd0C3a0aa9",
            7500,
            [
                {"siblingHash": "0xb579f5c13eeb27b66f36ee9352993cf06592fae6d57ddaab8173b514d816bca6", "isLeft": false},
                {"siblingHash": "0xb898fa82d49c05ad38b5b03121f95393f6d638af090b8bc856af6a5ade313d78", "isLeft": false},
                {"siblingHash": "0xfebca01c36ea33cc6c1590186c766592b5bdd3150fa46cb1cf094ff176e023c9", "isLeft": true}
            ]
        );
        expect(account7Result).to.be.equal(false);
    });
})

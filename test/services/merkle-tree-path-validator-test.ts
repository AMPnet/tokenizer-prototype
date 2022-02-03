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
        // Merkle tree with root hash 0xccd102c8ad222de27fa4463a41bcae172e4d4b0eddeeaa4dafe4bb979aa68c3c
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
            "0xccd102c8ad222de27fa4463a41bcae172e4d4b0eddeeaa4dafe4bb979aa68c3c",
            3,
            "0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266",
            1000,
            [
                "0x1fbd400bd5326802cf3e4f204a758a6262b480feb5d24a2331efb1eb1fa5f6e6",
                "0xc98149b58dee7d807e76dff466baae8fd6652144e979ac2fc82d9fa32e68dd3f",
                "0xd093f9d1eb3721e212189fe2d6691ba0e865c94e58ef25465c4cc3ef8e601094"
            ]
        );
        expect(account1Result).to.be.equal(true);

        let account2Result = await merkleTreePathValidatorService.containsNode(
            "0xccd102c8ad222de27fa4463a41bcae172e4d4b0eddeeaa4dafe4bb979aa68c3c",
            3,
            "0x70997970C51812dc3A010C7d01b50e0d17dc79C8",
            2000,
            [
                "0x0e7e48f58c5bd144faf53a9046591ec912af78cd6d8f0c1d8a41ab519e9b596f",
                "0x199ff36af77bbf4cf05c103265a5f946009431a4abbb28f57054c6ab8e657d07",
                "0xd093f9d1eb3721e212189fe2d6691ba0e865c94e58ef25465c4cc3ef8e601094"
            ]
        );
        expect(account2Result).to.be.equal(true);

        let account3Result = await merkleTreePathValidatorService.containsNode(
            "0xccd102c8ad222de27fa4463a41bcae172e4d4b0eddeeaa4dafe4bb979aa68c3c",
            3,
            "0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC",
            3000,
            [
                "0x5c4d5593904ecd1b7d9f868c57a384abd2cd75be094339ad8ab095a226212b55",
                "0xc98149b58dee7d807e76dff466baae8fd6652144e979ac2fc82d9fa32e68dd3f",
                "0xd093f9d1eb3721e212189fe2d6691ba0e865c94e58ef25465c4cc3ef8e601094"
            ]
        );
        expect(account3Result).to.be.equal(true);

        let account4Result = await merkleTreePathValidatorService.containsNode(
            "0xccd102c8ad222de27fa4463a41bcae172e4d4b0eddeeaa4dafe4bb979aa68c3c",
            3,
            "0x90F79bf6EB2c4f870365E785982E1f101E93b906",
            4000,
            [
                "0xb579f5c13eeb27b66f36ee9352993cf06592fae6d57ddaab8173b514d816bca6",
                "0x3fd3cc771a0dac8e044f8d6369b1e5317b29e38905d84690310338c7a8b92b46",
                "0x8cc9d677e018a88d1759c1e895897d137102bed87a8ef5ab7f68bfb3a5054d98"
            ]
        );
        expect(account4Result).to.be.equal(true);

        let account5Result = await merkleTreePathValidatorService.containsNode(
            "0xccd102c8ad222de27fa4463a41bcae172e4d4b0eddeeaa4dafe4bb979aa68c3c",
            3,
            "0x15d34AAf54267DB7D7c367839AAf71A00a2C6A65",
            5000,
            [
                "0x17eded8ad02538d86cb3968c49f57bf8f6610522689115d97799542e598a1de6",
                "0x199ff36af77bbf4cf05c103265a5f946009431a4abbb28f57054c6ab8e657d07",
                "0xd093f9d1eb3721e212189fe2d6691ba0e865c94e58ef25465c4cc3ef8e601094"
            ]
        );
        expect(account5Result).to.be.equal(true);

        let account6Result = await merkleTreePathValidatorService.containsNode(
            "0xccd102c8ad222de27fa4463a41bcae172e4d4b0eddeeaa4dafe4bb979aa68c3c",
            3,
            "0x9965507D1a55bcC2695C58ba16FB37d819B0A4dc",
            6000,
            [
                "0x752e282b9447f0caa9c85222d24f2cbfe6cf08d277349cca7a7ba42cfaac0c2f",
                "0x3fd3cc771a0dac8e044f8d6369b1e5317b29e38905d84690310338c7a8b92b46",
                "0x8cc9d677e018a88d1759c1e895897d137102bed87a8ef5ab7f68bfb3a5054d98"
            ]
        );
        expect(account6Result).to.be.equal(true);

        let account7Result = await merkleTreePathValidatorService.containsNode(
            "0xccd102c8ad222de27fa4463a41bcae172e4d4b0eddeeaa4dafe4bb979aa68c3c",
            3,
            "0x976EA74026E726554dB657fA54763abd0C3a0aa9",
            7000,
            [
                "0x0000000000000000000000000000000000000000000000000000000000000000",
                "0xac2379705bc597ab9d341a458f5bac996d71c3d06a0a3dccdfc84f3ceebf7a4a",
                "0x8cc9d677e018a88d1759c1e895897d137102bed87a8ef5ab7f68bfb3a5054d98"
            ]
        );
        expect(account7Result).to.be.equal(true);
    });

    it('should correctly determine when node is not contained in Merkle tree - wrong balance', async function() {
        // Merkle tree with root hash 0xccd102c8ad222de27fa4463a41bcae172e4d4b0eddeeaa4dafe4bb979aa68c3c
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
            "0xccd102c8ad222de27fa4463a41bcae172e4d4b0eddeeaa4dafe4bb979aa68c3c",
            3,
            "0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266",
            1500,
            [
                "0x1fbd400bd5326802cf3e4f204a758a6262b480feb5d24a2331efb1eb1fa5f6e6",
                "0xc98149b58dee7d807e76dff466baae8fd6652144e979ac2fc82d9fa32e68dd3f",
                "0xd093f9d1eb3721e212189fe2d6691ba0e865c94e58ef25465c4cc3ef8e601094"
            ]
        );
        expect(account1Result).to.be.equal(false);

        let account2Result = await merkleTreePathValidatorService.containsNode(
            "0xccd102c8ad222de27fa4463a41bcae172e4d4b0eddeeaa4dafe4bb979aa68c3c",
            3,
            "0x70997970C51812dc3A010C7d01b50e0d17dc79C8",
            2500,
            [
                "0x0e7e48f58c5bd144faf53a9046591ec912af78cd6d8f0c1d8a41ab519e9b596f",
                "0x199ff36af77bbf4cf05c103265a5f946009431a4abbb28f57054c6ab8e657d07",
                "0xd093f9d1eb3721e212189fe2d6691ba0e865c94e58ef25465c4cc3ef8e601094"
            ]
        );
        expect(account2Result).to.be.equal(false);

        let account3Result = await merkleTreePathValidatorService.containsNode(
            "0xccd102c8ad222de27fa4463a41bcae172e4d4b0eddeeaa4dafe4bb979aa68c3c",
            3,
            "0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC",
            3500,
            [
                "0x5c4d5593904ecd1b7d9f868c57a384abd2cd75be094339ad8ab095a226212b55",
                "0xc98149b58dee7d807e76dff466baae8fd6652144e979ac2fc82d9fa32e68dd3f",
                "0xd093f9d1eb3721e212189fe2d6691ba0e865c94e58ef25465c4cc3ef8e601094"
            ]
        );
        expect(account3Result).to.be.equal(false);

        let account4Result = await merkleTreePathValidatorService.containsNode(
            "0xccd102c8ad222de27fa4463a41bcae172e4d4b0eddeeaa4dafe4bb979aa68c3c",
            3,
            "0x90F79bf6EB2c4f870365E785982E1f101E93b906",
            4500,
            [
                "0xb579f5c13eeb27b66f36ee9352993cf06592fae6d57ddaab8173b514d816bca6",
                "0x3fd3cc771a0dac8e044f8d6369b1e5317b29e38905d84690310338c7a8b92b46",
                "0x8cc9d677e018a88d1759c1e895897d137102bed87a8ef5ab7f68bfb3a5054d98"
            ]
        );
        expect(account4Result).to.be.equal(false);

        let account5Result = await merkleTreePathValidatorService.containsNode(
            "0xccd102c8ad222de27fa4463a41bcae172e4d4b0eddeeaa4dafe4bb979aa68c3c",
            3,
            "0x15d34AAf54267DB7D7c367839AAf71A00a2C6A65",
            5500,
            [
                "0x17eded8ad02538d86cb3968c49f57bf8f6610522689115d97799542e598a1de6",
                "0x199ff36af77bbf4cf05c103265a5f946009431a4abbb28f57054c6ab8e657d07",
                "0xd093f9d1eb3721e212189fe2d6691ba0e865c94e58ef25465c4cc3ef8e601094"
            ]
        );
        expect(account5Result).to.be.equal(false);

        let account6Result = await merkleTreePathValidatorService.containsNode(
            "0xccd102c8ad222de27fa4463a41bcae172e4d4b0eddeeaa4dafe4bb979aa68c3c",
            3,
            "0x9965507D1a55bcC2695C58ba16FB37d819B0A4dc",
            6500,
            [
                "0x752e282b9447f0caa9c85222d24f2cbfe6cf08d277349cca7a7ba42cfaac0c2f",
                "0x3fd3cc771a0dac8e044f8d6369b1e5317b29e38905d84690310338c7a8b92b46",
                "0x8cc9d677e018a88d1759c1e895897d137102bed87a8ef5ab7f68bfb3a5054d98"
            ]
        );
        expect(account6Result).to.be.equal(false);

        let account7Result = await merkleTreePathValidatorService.containsNode(
            "0xccd102c8ad222de27fa4463a41bcae172e4d4b0eddeeaa4dafe4bb979aa68c3c",
            3,
            "0x976EA74026E726554dB657fA54763abd0C3a0aa9",
            7500,
            [
                "0x0000000000000000000000000000000000000000000000000000000000000000",
                "0xac2379705bc597ab9d341a458f5bac996d71c3d06a0a3dccdfc84f3ceebf7a4a",
                "0x8cc9d677e018a88d1759c1e895897d137102bed87a8ef5ab7f68bfb3a5054d98"
            ]
        );
        expect(account7Result).to.be.equal(false);
    });

    it('should correctly determine when node is not contained in Merkle tree - wrong tree depth', async function() {
        // Merkle tree with root hash 0xccd102c8ad222de27fa4463a41bcae172e4d4b0eddeeaa4dafe4bb979aa68c3c
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

        // wrong tree depth is provided in these tests

        let account1Result = await merkleTreePathValidatorService.containsNode(
            "0xccd102c8ad222de27fa4463a41bcae172e4d4b0eddeeaa4dafe4bb979aa68c3c",
            2,
            "0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266",
            1000,
            [
                "0x1fbd400bd5326802cf3e4f204a758a6262b480feb5d24a2331efb1eb1fa5f6e6",
                "0xc98149b58dee7d807e76dff466baae8fd6652144e979ac2fc82d9fa32e68dd3f",
                "0xd093f9d1eb3721e212189fe2d6691ba0e865c94e58ef25465c4cc3ef8e601094"
            ]
        );
        expect(account1Result).to.be.equal(false);

        let account2Result = await merkleTreePathValidatorService.containsNode(
            "0xccd102c8ad222de27fa4463a41bcae172e4d4b0eddeeaa4dafe4bb979aa68c3c",
            2,
            "0x70997970C51812dc3A010C7d01b50e0d17dc79C8",
            2000,
            [
                "0x0e7e48f58c5bd144faf53a9046591ec912af78cd6d8f0c1d8a41ab519e9b596f",
                "0x199ff36af77bbf4cf05c103265a5f946009431a4abbb28f57054c6ab8e657d07",
                "0xd093f9d1eb3721e212189fe2d6691ba0e865c94e58ef25465c4cc3ef8e601094"
            ]
        );
        expect(account2Result).to.be.equal(false);

        let account3Result = await merkleTreePathValidatorService.containsNode(
            "0xccd102c8ad222de27fa4463a41bcae172e4d4b0eddeeaa4dafe4bb979aa68c3c",
            2,
            "0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC",
            3000,
            [
                "0x5c4d5593904ecd1b7d9f868c57a384abd2cd75be094339ad8ab095a226212b55",
                "0xc98149b58dee7d807e76dff466baae8fd6652144e979ac2fc82d9fa32e68dd3f",
                "0xd093f9d1eb3721e212189fe2d6691ba0e865c94e58ef25465c4cc3ef8e601094"
            ]
        );
        expect(account3Result).to.be.equal(false);

        let account4Result = await merkleTreePathValidatorService.containsNode(
            "0xccd102c8ad222de27fa4463a41bcae172e4d4b0eddeeaa4dafe4bb979aa68c3c",
            2,
            "0x90F79bf6EB2c4f870365E785982E1f101E93b906",
            4000,
            [
                "0xb579f5c13eeb27b66f36ee9352993cf06592fae6d57ddaab8173b514d816bca6",
                "0x3fd3cc771a0dac8e044f8d6369b1e5317b29e38905d84690310338c7a8b92b46",
                "0x8cc9d677e018a88d1759c1e895897d137102bed87a8ef5ab7f68bfb3a5054d98"
            ]
        );
        expect(account4Result).to.be.equal(false);

        let account5Result = await merkleTreePathValidatorService.containsNode(
            "0xccd102c8ad222de27fa4463a41bcae172e4d4b0eddeeaa4dafe4bb979aa68c3c",
            2,
            "0x15d34AAf54267DB7D7c367839AAf71A00a2C6A65",
            5000,
            [
                "0x17eded8ad02538d86cb3968c49f57bf8f6610522689115d97799542e598a1de6",
                "0x199ff36af77bbf4cf05c103265a5f946009431a4abbb28f57054c6ab8e657d07",
                "0xd093f9d1eb3721e212189fe2d6691ba0e865c94e58ef25465c4cc3ef8e601094"
            ]
        );
        expect(account5Result).to.be.equal(false);

        let account6Result = await merkleTreePathValidatorService.containsNode(
            "0xccd102c8ad222de27fa4463a41bcae172e4d4b0eddeeaa4dafe4bb979aa68c3c",
            2,
            "0x9965507D1a55bcC2695C58ba16FB37d819B0A4dc",
            6000,
            [
                "0x752e282b9447f0caa9c85222d24f2cbfe6cf08d277349cca7a7ba42cfaac0c2f",
                "0x3fd3cc771a0dac8e044f8d6369b1e5317b29e38905d84690310338c7a8b92b46",
                "0x8cc9d677e018a88d1759c1e895897d137102bed87a8ef5ab7f68bfb3a5054d98"
            ]
        );
        expect(account6Result).to.be.equal(false);

        let account7Result = await merkleTreePathValidatorService.containsNode(
            "0xccd102c8ad222de27fa4463a41bcae172e4d4b0eddeeaa4dafe4bb979aa68c3c",
            2,
            "0x976EA74026E726554dB657fA54763abd0C3a0aa9",
            7000,
            [
                "0x0000000000000000000000000000000000000000000000000000000000000000",
                "0xac2379705bc597ab9d341a458f5bac996d71c3d06a0a3dccdfc84f3ceebf7a4a",
                "0x8cc9d677e018a88d1759c1e895897d137102bed87a8ef5ab7f68bfb3a5054d98"
            ]
        );
        expect(account7Result).to.be.equal(false);
    });
})

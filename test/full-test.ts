import { ethers } from "hardhat";
import { BigNumber, Contract, Signer } from "ethers";
import { expect } from "chai";

describe("Full test", function () {
  
  let deployer: Signer;
  let issuerOwner: Signer;
  let cfManagerOwner: Signer;
  
  let stablecoin: Contract;

  beforeEach(async function () {
    let accounts: Signer[] = await ethers.getSigners();
    deployer        = accounts[0];
    issuerOwner     = accounts[1];
    cfManagerOwner  = accounts[2];
    await initStablecoin();
  });

  it(
    `should successfully complete the flow:\n
          1)create Issuer\n
          2)create crowdfunding campaign\n
          3)successfully fund the project
    `,
    async function () {
      let amount = ethers.utils.parseEther("1");
      await expect(
        () => sendStablecoin(issuerOwner, amount)
      ).to.changeTokenBalance(stablecoin, issuerOwner, amount);
    }
    // TODO: - Implement test.
  );

  async function initStablecoin() {
    const supply = ethers.utils.parseEther("100000");
    const USDC = await ethers.getContractFactory("USDC", deployer);
    stablecoin = await USDC.deploy(supply);
  }

  async function sendStablecoin(to: Signer, amount: BigNumber) {
    let toAddress = await to.getAddress();
    await stablecoin.transfer(toAddress, amount);
  }
  
});

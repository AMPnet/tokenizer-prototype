import { ethers } from "hardhat";

async function main() {
    const accounts = await ethers.getSigners();
    const deployer = accounts[0];
    const deployerAddress = await deployer.getAddress();

    if (!process.env.STABLECOIN) { throw new Error("Missing STABLECOIN env variable.") }
    if (!process.env.RECEIVER) { throw new Error("Missing RECEIVER env variable.") }
    
    const stablecoin = await ethers.getContractAt("USDC", process.env.STABLECOIN);
    const receiver = process.env.RECEIVER;
    const amount = process.env.AMOUNT || "100000";
    const amountWei = await ethers.utils.parseEther(amount);
    const tx = await stablecoin.connect(deployer).transfer(receiver, amountWei);
    console.log(`Transfer transaction broadcasted!\n\thash: ${tx.hash}\n\tfrom: ${deployerAddress}\n\tto: ${receiver}\n\tamount: ${amountWei.toString()}`)
    await ethers.provider.waitForTransaction(tx.hash);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });

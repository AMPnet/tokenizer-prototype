// @ts-ignore
import { ethers } from "hardhat";
import { Contract } from "ethers";

export async function createCampaign(
    owner: String,
    mappedName: String,
    asset: Contract,
    pricePerToken: Number,
    softCapWei: Number,
    minInvestmentWei: Number,
    maxInvestmentWei: Number,
    whitelistRequired: boolean,
    info: String,
    cfManagerFactory: Contract,
    nameRegistry: Contract,
    feeRegistry: Contract
  ): Promise<Contract> {
    const cfManagerTx = await cfManagerFactory.create([
      owner,
      mappedName,
      asset.address,
      ethers.constants.AddressZero,
      ethers.constants.AddressZero,
      pricePerToken,
      0,
      softCapWei,
      minInvestmentWei,
      maxInvestmentWei,
      whitelistRequired,
      info,
      nameRegistry.address,
      feeRegistry.address
    ]);
    const receipt = await ethers.provider.waitForTransaction(cfManagerTx.hash);
    for (const log of receipt.logs) {
      try {
        const parsedLog = cfManagerFactory.interface.parseLog(log);
        if (parsedLog.name == "CfManagerSoftcapCreated") {
          const ownerAddress = parsedLog.args.creator;
          const cfManagerAddress = parsedLog.args.cfManager;
          const assetAddress = parsedLog.args.asset;
          console.log(`\nCrowdfunding Campaign deployed\n\tAt address: ${cfManagerAddress}\n\tOwner: ${ownerAddress}\n\tAsset: ${assetAddress}`);
          return (await ethers.getContractAt("CfManagerSoftcap", cfManagerAddress));
        }
        if (parsedLog.name == "CfManagerSoftcapVestingCreated") {
            const ownerAddress = parsedLog.args.creator;
            const cfManagerAddress = parsedLog.args.cfManager;
            const assetAddress = parsedLog.args.asset;
            console.log(`\nCrowdfunding Campaign [Vesting] deployed\n\tAt address: ${cfManagerAddress}\n\tOwner: ${ownerAddress}\n\tAsset: ${assetAddress}`);
            return (await ethers.getContractAt("CfManagerSoftcapVesting", cfManagerAddress));
        }
      } catch (_) {}
    }
    throw new Error("Campaign creation transaction failed.");
  }
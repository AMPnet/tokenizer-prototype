// @ts-ignore
import { ethers } from "hardhat";
import { Contract } from "ethers";
import { parseStablecoin } from "./helpers";

export async function createIssuerAssetCampaign(
    issuerOwner: String,
    issuerMappedName: String,
    issuerStablecoin: string,
    issuerWalletApprover: String,
    issuerInfo: String,
    assetOwner: String,
    assetMappedName: String,
    assetInitialTokenSupply: Number,
    assetWhitelistRequired: boolean,
    assetName: String,
    assetSymbol: String,
    assetInfo: String,
    cfManagerOwner: String,
    cfManagerMappedName: String,
    cfManagerPricePerToken: Number,
    cfManagerSoftcap: Number,
    cfManagerMinInvestment: Number,
    cfManagerMaxInvestment: Number,
    cfManagerTokensToSellAmount: Number,
    cfManagerWhitelistRequired: boolean,
    cfManagerInfo: String,
    issuerFactory: Contract,
    assetFactory: Contract,
    cfManagerFactory: Contract,
    deployerService: Contract,
    apxRegistry: Contract,
    nameRegistry: Contract
  ): Promise<Array<Contract>> {
    const stablecoin = await ethers.getContractAt("USDC", issuerStablecoin);
    const assetInitialTokenSupplyWei = ethers.utils.parseEther(assetInitialTokenSupply.toString());
    const cfManagerSoftcapWei = await parseStablecoin(cfManagerSoftcap, stablecoin);
    const cfManagerTokensToSellAmountWei = ethers.utils.parseEther(cfManagerTokensToSellAmount.toString());
    const cfManagerMinInvestmentWei = await parseStablecoin(cfManagerMinInvestment, stablecoin);
    const cfManagerMaxInvestmentWei = await parseStablecoin(cfManagerMaxInvestment, stablecoin);
    const deployTx = await deployerService.deployIssuerAssetCampaign(
      [
        issuerFactory.address,
        assetFactory.address,
        cfManagerFactory.address,
        issuerOwner,
        issuerMappedName,
        issuerStablecoin,
        issuerWalletApprover,
        issuerInfo,
        assetOwner,
        assetMappedName,
        assetInitialTokenSupplyWei,
        assetWhitelistRequired,
        assetName,
        assetSymbol,
        assetInfo,
        cfManagerOwner,
        cfManagerMappedName,
        cfManagerPricePerToken,
        cfManagerSoftcapWei,
        cfManagerMinInvestmentWei,
        cfManagerMaxInvestmentWei,
        cfManagerTokensToSellAmountWei,
        cfManagerWhitelistRequired,
        cfManagerInfo,
        apxRegistry.address,
        nameRegistry.address
      ]
    );
    const receipt = await ethers.provider.waitForTransaction(deployTx.hash);
    
    let issuerAddress: string;
    let assetAddress: string;
    let cfManagerAddress: string;
    for (const log of receipt.logs) {
      try {
        const parsedLog = issuerFactory.interface.parseLog(log);
        if (parsedLog.name == "IssuerCreated") {
          const ownerAddress = parsedLog.args.creator;
          issuerAddress = parsedLog.args.issuer;
          console.log(`\nIssuer deployed\n\tAt address: ${issuerAddress}\n\tOwner: ${ownerAddress}`);
        }
      } catch (_) {}
  
      try {
        const parsedLog = assetFactory.interface.parseLog(log);
        if (parsedLog.name == "AssetCreated") {
          const ownerAddress = parsedLog.args.creator;
          assetAddress = parsedLog.args.asset;
          console.log(`\nAsset deployed\n\tAt address: ${assetAddress}\n\tOwner: ${ownerAddress}`);
        }
      } catch (_) {}
  
      try {
        const parsedLog = cfManagerFactory.interface.parseLog(log);
        if (parsedLog.name == "CfManagerSoftcapCreated") {
          const ownerAddress = parsedLog.args.creator;
          const assetAddress = parsedLog.args.asset;
          cfManagerAddress = parsedLog.args.cfManager;
          console.log(`\nCrowdfunding Campaign deployed\n\tAt address: ${cfManagerAddress}\n\tOwner: ${ownerAddress}\n\tAsset: ${assetAddress}`);
        }
      } catch (_) {}
    }
    const issuer = await ethers.getContractAt("Issuer", issuerAddress);
    const asset = await ethers.getContractAt("Asset", assetAddress);
    const campaign = await ethers.getContractAt("CfManagerSoftcap", cfManagerAddress);
  
    return [issuer, asset, campaign];
  }
  
  export async function createAssetCampaign(
    issuer: Contract,
    assetOwner: String,
    assetMappedName: String,
    assetInitialTokenSupply: Number,
    assetWhitelistRequiredForRevenueClaim: boolean,
    assetWhitelistRequiredForLiquidationClaim: boolean,
    assetName: String,
    assetSymbol: String,
    assetInfo: String,
    cfManagerOwner: String,
    cfManagerMappedName: String,
    cfManagerPricePerToken: Number,
    cfManagerSoftcap: Number,
    cfManagerMinInvestment: Number,
    cfManagerMaxInvestment: Number,
    cfManagerTokensToSellAmount: Number,
    cfManagerWhitelistRequired: boolean,
    cfManagerInfo: String,
    apxRegistry: String,
    nameRegistry: String,
    feeManager: String,
    assetFactory: Contract,
    cfManagerFactory: Contract,
    deployerService: Contract
  ): Promise<Array<Contract>> {
    const stablecoinAddress = (await issuer.commonState()).stablecoin;
    const stablecoin = await ethers.getContractAt("USDC", stablecoinAddress);
    const assetInitialTokenSupplyWei = ethers.utils.parseEther(assetInitialTokenSupply.toString());
    const cfManagerSoftcapWei = await parseStablecoin(cfManagerSoftcap, stablecoin);
    const cfManagerMinInvestmentWei = await parseStablecoin(cfManagerMinInvestment, stablecoin);
    const cfManagerMaxInvestmentWei = await parseStablecoin(cfManagerMaxInvestment, stablecoin);
    const cfManagerTokensToSellAmountWei = ethers.utils.parseEther(cfManagerTokensToSellAmount.toString());
    const deployTx = await deployerService.deployAssetCampaign(
      [
        assetFactory.address,
        cfManagerFactory.address,
        issuer.address,
        assetOwner,
        assetMappedName,
        assetInitialTokenSupplyWei,
        assetWhitelistRequiredForRevenueClaim,
        assetWhitelistRequiredForLiquidationClaim,
        assetName,
        assetSymbol,
        assetInfo,
        cfManagerOwner,
        cfManagerMappedName,
        cfManagerPricePerToken,
        cfManagerSoftcapWei,
        cfManagerMinInvestmentWei,
        cfManagerMaxInvestmentWei,
        cfManagerTokensToSellAmountWei,
        cfManagerWhitelistRequired,
        cfManagerInfo,
        apxRegistry,
        nameRegistry,
        feeManager
      ]
    );
    const receipt = await ethers.provider.waitForTransaction(deployTx.hash);
  
    let assetAddress: string;
    let cfManagerAddress: string;
    for (const log of receipt.logs) {
      try {
        const parsedLog = assetFactory.interface.parseLog(log);
        if (parsedLog.name == "AssetCreated") {
          const ownerAddress = parsedLog.args.creator;
          assetAddress = parsedLog.args.asset;
          console.log(`\nAsset deployed\n\tAt address: ${assetAddress}\n\tOwner: ${ownerAddress}`);
        }
      } catch (_) {}
  
      try {
        const parsedLog = cfManagerFactory.interface.parseLog(log);
        if (parsedLog.name == "CfManagerSoftcapCreated") {
          const ownerAddress = parsedLog.args.creator;
          const assetAddress = parsedLog.args.asset;
          cfManagerAddress = parsedLog.args.cfManager;
          console.log(`\nCrowdfunding Campaign deployed\n\tAt address: ${cfManagerAddress}\n\tOwner: ${ownerAddress}\n\tAsset: ${assetAddress}`);
        }
      } catch (_) {}
    }
    const asset = await ethers.getContractAt("Asset", assetAddress);
    const campaign = await ethers.getContractAt("CfManagerSoftcap", cfManagerAddress);
  
    return [asset, campaign];
}

export async function createIssuerAssetTransferableCampaign(
    issuerOwner: String,
    issuerMappedName: String,
    issuerStablecoin: string,
    issuerWalletApprover: String,
    issuerInfo: String,
    assetOwner: String,
    assetMappedName: String,
    assetInitialTokenSupply: Number,
    assetWhitelistRequiredForRevenueClaim: boolean,
    assetWhitelistRequiredForLiquidationClaim: boolean,
    assetName: String,
    assetSymbol: String,
    assetInfo: String,
    cfManagerOwner: String,
    cfManagerMappedName: String,
    cfManagerPricePerToken: Number,
    cfManagerSoftcap: Number,
    cfManagerMinInvestment: Number,
    cfManagerMaxInvestment: Number,
    cfManagerTokensToSellAmount: Number,
    cfManagerWhitelistRequired: boolean,
    cfManagerInfo: String,
    apxRegistry: String,
    nameRegistry: String,
    issuerFactory: Contract,
    assetTransferableFactory: Contract,
    cfManagerFactory: Contract,
    deployerService: Contract
  ): Promise<Array<Contract>> {
    const stablecoin = await ethers.getContractAt("USDC", issuerStablecoin);
    const assetInitialTokenSupplyWei = ethers.utils.parseEther(assetInitialTokenSupply.toString());
    const cfManagerSoftcapWei = await parseStablecoin(cfManagerSoftcap, stablecoin);
    const cfManagerTokensToSellAmountWei = ethers.utils.parseEther(cfManagerTokensToSellAmount.toString());
    const cfManagerMinInvestmentWei = await parseStablecoin(cfManagerMinInvestment, stablecoin);
    const cfManagerMaxInvestmentWei = await parseStablecoin(cfManagerMaxInvestment, stablecoin);
    const deployTx = await deployerService.deployIssuerAssetTransferableCampaign(
      [
        issuerFactory.address,
        assetTransferableFactory.address,
        cfManagerFactory.address,
        issuerOwner,
        issuerMappedName,
        issuerStablecoin,
        issuerWalletApprover,
        issuerInfo,
        assetOwner,
        assetMappedName,
        assetInitialTokenSupplyWei,
        assetWhitelistRequiredForRevenueClaim,
        assetWhitelistRequiredForLiquidationClaim,
        assetName,
        assetSymbol,
        assetInfo,
        cfManagerOwner,
        cfManagerMappedName,
        cfManagerPricePerToken,
        cfManagerSoftcapWei,
        cfManagerMinInvestmentWei,
        cfManagerMaxInvestmentWei,
        cfManagerTokensToSellAmountWei,
        cfManagerWhitelistRequired,
        cfManagerInfo,
        apxRegistry,
        nameRegistry
      ]
    );
    const receipt = await ethers.provider.waitForTransaction(deployTx.hash);
    
    let issuerAddress: string;
    let assetTransferableAddress: string;
    let cfManagerAddress: string;
    for (const log of receipt.logs) {
      try {
        const parsedLog = issuerFactory.interface.parseLog(log);
        if (parsedLog.name == "IssuerCreated") {
          const ownerAddress = parsedLog.args.creator;
          issuerAddress = parsedLog.args.issuer;
          console.log(`\nIssuer deployed\n\tAt address: ${issuerAddress}\n\tOwner: ${ownerAddress}`);
        }
      } catch (_) {}
  
      try {
        const parsedLog = assetTransferableFactory.interface.parseLog(log);
        if (parsedLog.name == "AssetTransferableCreated") {
          const ownerAddress = parsedLog.args.creator;
          assetTransferableAddress = parsedLog.args.asset;
          console.log(`\nAsset deployed\n\tAt address: ${assetTransferableAddress}\n\tOwner: ${ownerAddress}`);
        }
      } catch (_) {}
  
      try {
        const parsedLog = cfManagerFactory.interface.parseLog(log);
        if (parsedLog.name == "CfManagerSoftcapCreated") {
          const ownerAddress = parsedLog.args.creator;
          const assetAddress = parsedLog.args.asset;
          cfManagerAddress = parsedLog.args.cfManager;
          console.log(`\nCrowdfunding Campaign deployed\n\tAt address: ${cfManagerAddress}\n\tOwner: ${ownerAddress}\n\tAsset: ${assetAddress}`);
        }
      } catch (_) {}
    }
    const issuer = await ethers.getContractAt("Issuer", issuerAddress);
    const assetTransferable = await ethers.getContractAt("AssetTransferable", assetTransferableAddress);
    const campaign = await ethers.getContractAt("CfManagerSoftcap", cfManagerAddress);
  
    return [issuer, assetTransferable, campaign];
}

export async function createAssetTransferableCampaign(
    issuer: Contract,
    assetOwner: String,
    assetMappedName: String,
    assetInitialTokenSupply: Number,
    assetWhitelistRequiredForRevenueClaim: boolean,
    assetWhitelistRequiredForLiquidationClaim: boolean,
    assetName: String,
    assetSymbol: String,
    assetInfo: String,
    cfManagerOwner: String,
    cfManagerMappedName: String,
    cfManagerPricePerToken: Number,
    cfManagerSoftcap: Number,
    cfManagerMinInvestment: Number,
    cfManagerMaxInvestment: Number,
    cfManagerTokensToSellAmount: Number,
    cfManagerWhitelistRequired: boolean,
    cfManagerInfo: String,
    apxRegistry: String,
    nameRegistry: String,
    feeManager: String,
    assetTransferableFactory: Contract,
    cfManagerFactory: Contract,
    deployerService: Contract
  ): Promise<Array<Contract>> {
    const stablecoinAddress = (await issuer.commonState()).stablecoin;
    const stablecoin = await ethers.getContractAt("USDC", stablecoinAddress);
    const assetInitialTokenSupplyWei = ethers.utils.parseEther(assetInitialTokenSupply.toString());
    const cfManagerSoftcapWei = await parseStablecoin(cfManagerSoftcap, stablecoin);
    const cfManagerMinInvestmentWei = await parseStablecoin(cfManagerMinInvestment, stablecoin);
    const cfManagerMaxInvestmentWei = await parseStablecoin(cfManagerMaxInvestment, stablecoin);
    const cfManagerTokensToSellAmountWei = ethers.utils.parseEther(cfManagerTokensToSellAmount.toString());
    const deployTx = await deployerService.deployAssetTransferableCampaign(
      [
        assetTransferableFactory.address,
        cfManagerFactory.address,
        issuer.address,
        assetOwner,
        assetMappedName,
        assetInitialTokenSupplyWei,
        assetWhitelistRequiredForRevenueClaim,
        assetWhitelistRequiredForLiquidationClaim,
        assetName,
        assetSymbol,
        assetInfo,
        cfManagerOwner,
        cfManagerMappedName,
        cfManagerPricePerToken,
        cfManagerSoftcapWei,
        cfManagerMinInvestmentWei,
        cfManagerMaxInvestmentWei,
        cfManagerTokensToSellAmountWei,
        cfManagerWhitelistRequired,
        cfManagerInfo,
        apxRegistry,
        nameRegistry,
        feeManager
      ]
    );
    const receipt = await ethers.provider.waitForTransaction(deployTx.hash);
  
    let assetTransferableAddress: string;
    let cfManagerAddress: string;
    for (const log of receipt.logs) {
      try {
        const parsedLog = assetTransferableFactory.interface.parseLog(log);
        if (parsedLog.name == "AssetTransferableCreated") {
          const ownerAddress = parsedLog.args.creator;
          assetTransferableAddress = parsedLog.args.asset;
          console.log(`\nAssetTransferable deployed\n\tAt address: ${assetTransferableAddress}\n\tOwner: ${ownerAddress}`);
        }
      } catch (_) {}
  
      try {
        const parsedLog = cfManagerFactory.interface.parseLog(log);
        if (parsedLog.name == "CfManagerSoftcapCreated") {
          const ownerAddress = parsedLog.args.creator;
          const assetAddress = parsedLog.args.asset;
          cfManagerAddress = parsedLog.args.cfManager;
          console.log(`\nCrowdfunding Campaign deployed\n\tAt address: ${cfManagerAddress}\n\tOwner: ${ownerAddress}\n\tAsset: ${assetAddress}`);
        }
      } catch (_) {}
    }
    const assetTransferable = await ethers.getContractAt("AssetTransferable", assetTransferableAddress);
    const campaign = await ethers.getContractAt("CfManagerSoftcap", cfManagerAddress);

    return [assetTransferable, campaign];
}

export async function createAssetSimpleCampaignVesting(
  issuer: Contract,
  assetOwner: String,
  assetMappedName: String,
  assetInitialTokenSupply: Number,
  assetName: String,
  assetSymbol: String,
  assetInfo: String,
  cfManagerOwner: String,
  cfManagerMappedName: String,
  cfManagerPricePerToken: Number,
  cfManagerSoftcap: Number,
  cfManagerMinInvestment: Number,
  cfManagerMaxInvestment: Number,
  cfManagerTokensToSellAmount: Number,
  cfManagerWhitelistRequired: boolean,
  cfManagerInfo: String,
  nameRegistry: String,
  feeManager: String,
  assetSimpleFactory: Contract,
  cfManagerVestingFactory: Contract,
  deployerService: Contract
): Promise<Array<Contract>> {
  const stablecoinAddress = (await issuer.commonState()).stablecoin;
  const stablecoin = await ethers.getContractAt("USDC", stablecoinAddress);
  const assetInitialTokenSupplyWei = ethers.utils.parseEther(assetInitialTokenSupply.toString());
  const cfManagerSoftcapWei = await parseStablecoin(cfManagerSoftcap, stablecoin);
  const cfManagerMinInvestmentWei = await parseStablecoin(cfManagerMinInvestment, stablecoin);
  const cfManagerMaxInvestmentWei = await parseStablecoin(cfManagerMaxInvestment, stablecoin);
  const cfManagerTokensToSellAmountWei = ethers.utils.parseEther(cfManagerTokensToSellAmount.toString());
  const deployTx = await deployerService.deployAssetSimpleCampaignVesting(
    [
      assetSimpleFactory.address,
      cfManagerVestingFactory.address,
      issuer.address,
      assetOwner,
      assetMappedName,
      assetInitialTokenSupplyWei,
      assetName,
      assetSymbol,
      assetInfo,
      cfManagerOwner,
      cfManagerMappedName,
      cfManagerPricePerToken,
      cfManagerSoftcapWei,
      cfManagerMinInvestmentWei,
      cfManagerMaxInvestmentWei,
      cfManagerTokensToSellAmountWei,
      cfManagerWhitelistRequired,
      cfManagerInfo,
      nameRegistry,
      feeManager
    ]
  );
  const receipt = await ethers.provider.waitForTransaction(deployTx.hash);

  let assetSimpleAddress: string;
  let cfManagerVestingAddress: string;
  for (const log of receipt.logs) {
    try {
      const parsedLog = assetSimpleFactory.interface.parseLog(log);
      if (parsedLog.name == "AssetSimpleCreated") {
        const ownerAddress = parsedLog.args.creator;
        assetSimpleAddress = parsedLog.args.asset;
        console.log(`\nAssetSimple deployed\n\tAt address: ${assetSimpleAddress}\n\tOwner: ${ownerAddress}`);
      }
    } catch (_) {}

    try {
      const parsedLog = cfManagerVestingFactory.interface.parseLog(log);
      if (parsedLog.name == "CfManagerSoftcapVestingCreated") {
        const ownerAddress = parsedLog.args.creator;
        const assetAddress = parsedLog.args.asset;
        cfManagerVestingAddress = parsedLog.args.cfManager;
        console.log(`\nCrowdfunding Campaign Vesting deployed\n\tAt address: ${cfManagerVestingAddress}\n\tOwner: ${ownerAddress}\n\tAsset: ${assetAddress}`);
      }
    } catch (_) {}
  }
  const assetSimple = await ethers.getContractAt("AssetSimple", assetSimpleAddress);
  const campaign = await ethers.getContractAt("CfManagerSoftcapVesting", cfManagerVestingAddress);

  return [assetSimple, campaign];
}

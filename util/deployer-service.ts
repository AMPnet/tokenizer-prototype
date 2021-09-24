import { ethers } from "hardhat";
import { Contract } from "ethers";

export async function createIssuerAssetCampaign(
    issuerOwner: String,
    issuerMappedName: String,
    issuerStablecoin: String,
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
    const assetInitialTokenSupplyWei = ethers.utils.parseEther(assetInitialTokenSupply.toString());
    const cfManagerSoftcapWei = ethers.utils.parseEther(cfManagerSoftcap.toString());
    const cfManagerTokensToSellAmountWei = ethers.utils.parseEther(cfManagerTokensToSellAmount.toString());
    const cfManagerMinInvestmentWei = ethers.utils.parseEther(cfManagerMinInvestment.toString());
    const cfManagerMaxInvestmentWei = ethers.utils.parseEther(cfManagerMaxInvestment.toString());
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
    assetFactory: Contract,
    cfManagerFactory: Contract,
    deployerService: Contract
  ): Promise<Array<Contract>> {
    const assetInitialTokenSupplyWei = ethers.utils.parseEther(assetInitialTokenSupply.toString());
    const cfManagerSoftcapWei = ethers.utils.parseEther(cfManagerSoftcap.toString());
    const cfManagerMinInvestmentWei = ethers.utils.parseEther(cfManagerMinInvestment.toString());
    const cfManagerMaxInvestmentWei = ethers.utils.parseEther(cfManagerMaxInvestment.toString());
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
        nameRegistry
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
    issuerStablecoin: String,
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
    childChainManager: String,
    issuerFactory: Contract,
    assetTransferableFactory: Contract,
    cfManagerFactory: Contract,
    deployerService: Contract
  ): Promise<Array<Contract>> {
    const assetInitialTokenSupplyWei = ethers.utils.parseEther(assetInitialTokenSupply.toString());
    const cfManagerSoftcapWei = ethers.utils.parseEther(cfManagerSoftcap.toString());
    const cfManagerTokensToSellAmountWei = ethers.utils.parseEther(cfManagerTokensToSellAmount.toString());
    const cfManagerMinInvestmentWei = ethers.utils.parseEther(cfManagerMinInvestment.toString());
    const cfManagerMaxInvestmentWei = ethers.utils.parseEther(cfManagerMaxInvestment.toString());
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
        nameRegistry,
        childChainManager
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
    childChainManager: String,
    assetTransferableFactory: Contract,
    cfManagerFactory: Contract,
    deployerService: Contract
  ): Promise<Array<Contract>> {
    const assetInitialTokenSupplyWei = ethers.utils.parseEther(assetInitialTokenSupply.toString());
    const cfManagerSoftcapWei = ethers.utils.parseEther(cfManagerSoftcap.toString());
    const cfManagerMinInvestmentWei = ethers.utils.parseEther(cfManagerMinInvestment.toString());
    const cfManagerMaxInvestmentWei = ethers.utils.parseEther(cfManagerMaxInvestment.toString());
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
        childChainManager
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

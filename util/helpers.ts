// @ts-ignore
import { ethers } from "hardhat";
import { Contract, Signer, BigNumber } from "ethers";
import * as filters from "./filters";
import { log } from "./utils";

const config = {
  confirmationsForDeploy: 1
}

export async function deployStablecoin(deployer: Signer, supply: number | string, precision: number | string, opts?: { logOutput: boolean }, confirmations: number = config.confirmationsForDeploy): Promise<Contract> {
  const supplyWei = ethers.utils.parseUnits(String(supply), String(precision));
  const USDC = await ethers.getContractFactory("USDC", deployer);
  const stablecoin = await USDC.deploy(supplyWei, precision);
  await ethers.provider.waitForTransaction(stablecoin.deployTransaction.hash, confirmations)
  log(`\nStablecoin deployed\n\tAt address: ${stablecoin.address}`, opts);
  return stablecoin;
}

export async function parseStablecoin(amount: number | string | Number, stablecoin: Contract): Promise<BigNumber> {
  const decimals = await stablecoin.decimals();
  return ethers.utils.parseUnits(String(amount), decimals);
}

export async function deployApxRegistry(deployer: Signer, masterOwner: string, assetManager: string, priceManager: string, opts?: { logOutput: boolean }, confirmations: number = config.confirmationsForDeploy): Promise<Contract> {
  const ApxRegistry = await ethers.getContractFactory("ApxAssetsRegistry", deployer);
  const apxRegistry = await ApxRegistry.deploy(masterOwner, assetManager, priceManager);
  await ethers.provider.waitForTransaction(apxRegistry.deployTransaction.hash, confirmations)
  log(`\nApxRegistry deployed\n\tAt address: ${apxRegistry.address}`, opts);
  return apxRegistry;
}

export async function deployCampaignFeeManager(deployer: Signer, owner: string, treasury: string, opts?: { logOutput: boolean }, confirmations: number = config.confirmationsForDeploy): Promise<Contract> {
  const CampaignFeeManager = await ethers.getContractFactory("CampaignFeeManager", deployer);
  const campaignFeeManager = await CampaignFeeManager.deploy(owner, treasury);
  await ethers.provider.waitForTransaction(campaignFeeManager.deployTransaction.hash, confirmations)
  log(`\nCampaignFeeManager deployed\n\tAt address: ${campaignFeeManager.address}`, opts);
  return campaignFeeManager;
}

export async function deployRevenueFeeManager(deployer: Signer, owner: string, treasury: string, opts?: { logOutput: boolean }, confirmations: number = config.confirmationsForDeploy): Promise<Contract> {
  const RevenueFeeManager = await ethers.getContractFactory("RevenueFeeManager", deployer);
  const revenueFeeManager = await RevenueFeeManager.deploy(owner, treasury);
  await ethers.provider.waitForTransaction(revenueFeeManager.deployTransaction.hash, confirmations);
  log(`\RevenueFeeManager deployed\n\tAt address: ${revenueFeeManager.address}`, opts);
  return revenueFeeManager;
}

export async function deployMerkleTreePathValidator(deployer: Signer, opts?: { logOutput: boolean }, confirmations: number = config.confirmationsForDeploy): Promise<Contract> {
  const MerkleTreePathValidator = await ethers.getContractFactory("MerkleTreePathValidator", deployer);
  const merkleTreePathValidator = await MerkleTreePathValidator.deploy();
  await ethers.provider.waitForTransaction(merkleTreePathValidator.deployTransaction.hash, confirmations)
  log(`\nMerkleTreePathValidator deployed\n\tAt address: ${merkleTreePathValidator.address}`, opts);
  return merkleTreePathValidator;
}

export async function deployPayoutManager(deployer: Signer, merkleTreePathValidatorAddress: string, revenueFeeManagerAddress: string, opts?: { logOutput: boolean }, confirmations: number = config.confirmationsForDeploy): Promise<Contract> {
  const PayoutManager = await ethers.getContractFactory("PayoutManager", deployer);
  const payoutManager = await PayoutManager.deploy(merkleTreePathValidatorAddress, revenueFeeManagerAddress);
  await ethers.provider.waitForTransaction(payoutManager.deployTransaction.hash, confirmations)
  log(`\nPayoutManager deployed\n\tAt address: ${payoutManager.address}`, opts);
  return payoutManager;
}

export async function deployTimeLockManager(deployer: Signer, opts?: { logOutput: boolean }, confirmations: number = config.confirmationsForDeploy): Promise<Contract> {
  const TimeLockManager = await ethers.getContractFactory("TimeLockManager", deployer);
  const timeLockManager = await TimeLockManager.deploy();
  await ethers.provider.waitForTransaction(timeLockManager.deployTransaction.hash, confirmations)
  log(`\nTimeLockManager deployed\n\tAt address: ${timeLockManager.address}`, opts);
  return timeLockManager;
}

export async function deployMirroredToken(deployer: Signer, name: string, symbol: string, originalToken: string, opts?: { logOutput: boolean }, confirmations: number = config.confirmationsForDeploy): Promise<Contract> {
  const MirroredToken = await ethers.getContractFactory("MirroredToken", deployer);
  const mirroredToken = await MirroredToken.deploy(name, symbol, originalToken);
  await ethers.provider.waitForTransaction(mirroredToken.deployTransaction.hash, confirmations)
  log(`\nMirroredToken deployed\n\tAt address: ${mirroredToken.address}`, opts);
  return mirroredToken;
}

export async function deployNameRegistry(deployer: Signer, masterOwner: string, factories: string[], opts?: { logOutput: boolean }, confirmations: number = config.confirmationsForDeploy): Promise<Contract> {
  const NameRegistry = await ethers.getContractFactory("NameRegistry", deployer);
  const isWhitelisted: boolean[] = factories.map(_ => true);
  const nameRegistry = await NameRegistry.deploy(masterOwner, factories, isWhitelisted);
  await ethers.provider.waitForTransaction(nameRegistry.deployTransaction.hash, confirmations)
  log(`\nNameRegistry deployed\n\tAt address: ${nameRegistry.address}`, opts);
  return nameRegistry;
}

export async function deployFactories(deployer: Signer, opts?: { logOutput: boolean }, confirmations: number = config.confirmationsForDeploy): Promise<Contract[]> {
  const zeroAddr = ethers.constants.AddressZero;
  return [
    await deployIssuerFactory(deployer, opts, zeroAddr, confirmations),
    await deployAssetFactory(deployer, opts, zeroAddr, confirmations),
    await deployAssetTransferableFactory(deployer, opts, zeroAddr, confirmations),
    await deployAssetSimpleFactory(deployer, opts, zeroAddr, confirmations),
    await deployCfManagerFactory(deployer, opts, zeroAddr, confirmations),
    await deployCfManagerVestingFactory(deployer, opts, zeroAddr, confirmations)
  ];
}

export async function deployServices(deployer: Signer, masterWalletApprover: string, rewardPerApprove: string, balanceThresholdForReward: string, opts?: { logOutput: boolean }): Promise<Contract[]> {
  return [
    await deployWalletApproverService(deployer, masterWalletApprover, [ ], rewardPerApprove, opts),
    await deployDeployerService(deployer, opts),
    await deployQueryService(deployer, opts),
    await deployInvestService(deployer, opts),
    await deployFaucetService(deployer, masterWalletApprover, [ ], rewardPerApprove, balanceThresholdForReward, opts),
    await deployPayoutService(deployer, opts)
  ];
}

export async function deployWalletApproverService(
  deployer: Signer,
  masterWalletApprover: string,
  walletApprovers: string[],
  rewardPerApproval: string,
  opts?: { logOutput: boolean },
  confirmations: number = config.confirmationsForDeploy,
): Promise<Contract> {
  const WalletApproverService = await ethers.getContractFactory("WalletApproverService", deployer);
  const rewardPerApprovalWei = ethers.utils.parseEther(rewardPerApproval);
  const walletApproverService = await WalletApproverService.deploy(masterWalletApprover, walletApprovers, rewardPerApprovalWei);
  await ethers.provider.waitForTransaction(walletApproverService.deployTransaction.hash, confirmations)
  log(`\nWallet approver service deployed\n\tAt address: ${walletApproverService.address}\n\tReward per approval: ${rewardPerApproval} ETH`, opts);
  return walletApproverService;
}

export async function deployDeployerService(deployer: Signer, opts?: { logOutput: boolean }, confirmations: number = config.confirmationsForDeploy): Promise<Contract> {
  const DeployerService = await ethers.getContractFactory("DeployerService", deployer);
  const deployerService = await DeployerService.deploy();
  await ethers.provider.waitForTransaction(deployerService.deployTransaction.hash, confirmations)
  log(`\nDeployer service deployed\n\tAt address: ${deployerService.address}`, opts);
  return deployerService;
}

export async function deployQueryService(deployer: Signer, opts?: { logOutput: boolean }, confirmations: number = config.confirmationsForDeploy): Promise<Contract> {
  const QueryService = await ethers.getContractFactory("QueryService", deployer);
  const queryService = await QueryService.deploy();
  await ethers.provider.waitForTransaction(queryService.deployTransaction.hash, confirmations)
  log(`\nQuery service deployed\n\tAt address: ${queryService.address}`, opts);
  return queryService;
}

export async function deployInvestService(deployer: Signer, opts?: { logOutput: boolean }, confirmations: number = config.confirmationsForDeploy): Promise<Contract> {
  const InvestService = await ethers.getContractFactory("InvestService", deployer);
  const investService = await InvestService.deploy();
  await ethers.provider.waitForTransaction(investService.deployTransaction.hash, confirmations)
  log(`\nInvest service deployed\n\tAt address: ${investService.address}`, opts);
  return investService;
}

export async function deployFaucetService(
  deployer: Signer,
  masterCaller: string,
  allowedCallers: string[],
  reward: string,
  balanceThresholdForReward: string,
  opts?: { logOutput: boolean },
  confirmations: number = config.confirmationsForDeploy
): Promise<Contract> {
  const FaucetService = await ethers.getContractFactory("FaucetService", deployer);
  const rewardWei = ethers.utils.parseEther(reward);
  const thresholdWei = ethers.utils.parseEther(balanceThresholdForReward);
  const faucetService = await FaucetService.deploy(
      masterCaller, allowedCallers, rewardWei, thresholdWei
  );
  await ethers.provider.waitForTransaction(faucetService.deployTransaction.hash, confirmations)
  log(`\nFaucet service deployed\n\tAt address: ${faucetService.address}\n\tReward per approval: ${reward} ETH\n\tBalance threshold for reward: ${balanceThresholdForReward} ETH`, opts);
  return faucetService;
}

export async function deployPayoutService(
  deployer: Signer,
  opts?: { logOutput: boolean },
  confirmations: number = config.confirmationsForDeploy
): Promise<Contract> {
  const PayoutService = await ethers.getContractFactory("PayoutService", deployer);
  const payoutService = await PayoutService.deploy();
  await ethers.provider.waitForTransaction(payoutService.deployTransaction.hash, confirmations);
  log(`\nPayout service deployed\n\tAt address: ${payoutService.address}`, opts);
  return payoutService;
}

export async function deployIssuerFactory(deployer: Signer, opts?: { logOutput: boolean }, oldFactory: string = ethers.constants.AddressZero, confirmations: number = config.confirmationsForDeploy): Promise<Contract> {
  const IssuerFactory = await ethers.getContractFactory("IssuerFactory", deployer);
  const issuerFactory = await IssuerFactory.deploy(oldFactory);
  await ethers.provider.waitForTransaction(issuerFactory.deployTransaction.hash, confirmations)
  log(`\nIssuerFactory deployed\n\tAt address: ${issuerFactory.address}`, opts);
  return issuerFactory;
}

export async function deployAssetFactory(deployer: Signer, opts?: { logOutput: boolean }, oldFactory: string = ethers.constants.AddressZero, confirmations: number = config.confirmationsForDeploy): Promise<Contract> {
  const AssetDeployer = await ethers.getContractFactory("AssetDeployer", deployer);
  const assetDeployer = await AssetDeployer.deploy();
  await ethers.provider.waitForTransaction(assetDeployer.deployTransaction.hash, confirmations)
  log(`\nAssetDeployer deployed\n\tAt address: ${assetDeployer.address}`, opts);
  const AssetFactory = await ethers.getContractFactory("AssetFactory", deployer);
  const assetFactory = await AssetFactory.deploy(assetDeployer.address, oldFactory);
  await ethers.provider.waitForTransaction(assetFactory.deployTransaction.hash, confirmations)
  log(`\nAssetFactory deployed\n\tAt address: ${assetFactory.address}`, opts);
  return assetFactory;
}

export async function deployAssetSimpleFactory(deployer: Signer, opts?: { logOutput: boolean }, oldFactory: string = ethers.constants.AddressZero, confirmations: number = config.confirmationsForDeploy): Promise<Contract> {
  const AssetFactory = await ethers.getContractFactory("AssetSimpleFactory", deployer);
  const assetFactory = await AssetFactory.deploy(oldFactory);
  await ethers.provider.waitForTransaction(assetFactory.deployTransaction.hash, confirmations)
  log(`\nAssetSimpleFactory deployed\n\tAt address: ${assetFactory.address}`, opts);
  return assetFactory;
}

export async function deployAssetTransferableFactory(deployer: Signer, opts?: { logOutput: boolean }, oldFactory: string = ethers.constants.AddressZero, confirmations: number = config.confirmationsForDeploy): Promise<Contract> {
  const AssetTransferableDeployer = await ethers.getContractFactory("AssetTransferableDeployer", deployer);
  const assetTransferableDeployer = await AssetTransferableDeployer.deploy();
  await ethers.provider.waitForTransaction(assetTransferableDeployer.deployTransaction.hash, confirmations)
  log(`\nAssetTransferableDeployer deployed\n\tAt address: ${assetTransferableDeployer.address}`, opts);
  const AssetTransferableFactory = await ethers.getContractFactory("AssetTransferableFactory", deployer);
  const assetTransferableFactory = await AssetTransferableFactory.deploy(assetTransferableDeployer.address, oldFactory);
  await ethers.provider.waitForTransaction(assetTransferableFactory.deployTransaction.hash, confirmations)
  log(`\nAssetTransferableFactory deployed\n\tAt address: ${assetTransferableFactory.address}`, opts);
  return assetTransferableFactory;
}

export async function deployCfManagerFactory(deployer: Signer, opts?: { logOutput: boolean }, oldFactory: string = ethers.constants.AddressZero, confirmations: number = config.confirmationsForDeploy): Promise<Contract> {
  const CfManagerFactory = await ethers.getContractFactory("CfManagerSoftcapFactory", deployer);
  const cfManagerFactory = await CfManagerFactory.deploy(oldFactory);
  await ethers.provider.waitForTransaction(cfManagerFactory.deployTransaction.hash, confirmations)
  log(`\nCfManagerFactory deployed\n\tAt address: ${cfManagerFactory.address}`, opts);
  return cfManagerFactory;
}

export async function deployCfManagerVestingFactory(deployer: Signer, opts?: { logOutput: boolean }, oldFactory: string = ethers.constants.AddressZero, confirmations: number = config.confirmationsForDeploy): Promise<Contract> {
  const CfManagerVestingFactory = await ethers.getContractFactory("CfManagerSoftcapVestingFactory", deployer);
  const cfManagerFactory = await CfManagerVestingFactory.deploy(oldFactory);
  await ethers.provider.waitForTransaction(cfManagerFactory.deployTransaction.hash, confirmations)
  log(`\nCfManagerVestingFactory deployed\n\tAt address: ${cfManagerFactory.address}`, opts);
  return cfManagerFactory;
}

/**
 * Creates the issuer instance.
 * Issuer has to be created before any of the assets or crowdfunding campaigns was created.
 * One investment platform instance (one domain) is mapped to one Issuer instance.
 * This is where the whitelisted addresses are stored. Issuer also holds the address of the
 * stablecoin to be accepted for the investments and revenue share payouts.
 *
 * @param from Creator's signer object
 * @param stablecoin Stablecoin contract instance accepted as the payment method for this issuer
 * @param walletApproverAddress Address of the wallet approver (wallet with the rights to whitelist addresses).
 *                              This will be set to our auto-approver-script's wallet if the manager
 *                              chooses to auto-approve all the wallets with completed kyc.
 * @param info Ipfs hash representing general investment platform instance info (colors, logo url, etc)
 * @param issuerFactory Issuer factory contract (predeployed and sitting at well known address)
 * @returns Contract instance of the deployed issuer, already connected to the owner's signer object
 */
export async function createIssuer(
  owner: String,
  mappedName: String,
  stablecoin: Contract,
  walletApproverAddress: String,
  info: String,
  issuerFactory: Contract,
  nameRegistry: Contract,
  opts?: { logOutput: boolean }
): Promise<Contract> {
  const issuerTx = await issuerFactory.create(
    owner,
    mappedName,
    stablecoin.address,
    walletApproverAddress,
    info,
    nameRegistry.address
  );
  const receipt = await ethers.provider.waitForTransaction(issuerTx.hash);
  // console.log("issuer deployed, scanning for events", receipt)
  for (const recLog of receipt.logs) {
    try {
      const parsedLog = issuerFactory.interface.parseLog(recLog);
      // console.log("parsedLog", parsedLog);
      if (parsedLog.name == "IssuerCreated") {
        const ownerAddress = parsedLog.args.creator;
        // console.log("parsed creator", ownerAddress);
        const issuerAddress = parsedLog.args.issuer;
        log(`\nIssuer deployed\n\tAt address: ${issuerAddress}\n\tOwner: ${ownerAddress}`, opts);
        return (await ethers.getContractAt("Issuer", issuerAddress));
      }
    } catch (_) {}
  }
  throw new Error("Issuer creation transaction failed.");
}

/**
 * Creates an Asset which is basically an ERC-20 token.
 * An asset has to be created before the crowdfunding campaign with the predefined token supply.
 * The full token supply is automatically owned by the token creator.
 *
 * @param from Creator's signer object
 * @param issuer Asset's issuer contract instance
 * @param initialTokenSupply Total number of tokens to be created. Not changeable afterwards.
 * @param whitelistRequiredForTransfer If set to true, tokens will be transferable only between the whitelisted addresses
 * @param name Asset token name (For example APPLE INC.)
 * @param symbol Asset token symbol/ticker (For example APPL)
 * @param info Asset info ipfs hash providing more than just a name and the ticker (if necessary)
 * @param assetFactory Asset factory contract (predeployed and sitting at well known address)
 * @returns Contract instance of the deployed asset token, already connected to the owner's signer object
 */
export async function createAsset(
  owner: String,
  issuer: Contract,
  mappedName: String,
  initialTokenSupply: Number,
  transferable: boolean,
  whitelistRequiredForRevenueClaim: boolean,
  whitelistRequiredForLiquidationClaim: boolean,
  name: String,
  symbol: String,
  info: String,
  assetFactory: Contract,
  nameRegistry: Contract,
  apxRegistry: Contract,
  opts?: { logOutput: boolean }
): Promise<Contract> {
  const createAssetTx = await assetFactory.create([
      owner,
      issuer.address,
      apxRegistry.address,
      nameRegistry.address,
      mappedName,
      ethers.utils.parseEther(initialTokenSupply.toString()),
      transferable,
      whitelistRequiredForRevenueClaim,
      whitelistRequiredForLiquidationClaim,
      name,
      symbol,
      info
    ]
  );
  const receipt = await ethers.provider.waitForTransaction(createAssetTx.hash);
  for (const recLog of receipt.logs) {
    try {
      const parsedLog = assetFactory.interface.parseLog(recLog);
      if (parsedLog.name == "AssetCreated") {
        const ownerAddress = parsedLog.args.creator;
        const assetAddress = parsedLog.args.asset;
        log(`\nAsset deployed\n\tAt address: ${assetAddress}\n\tOwner: ${ownerAddress}`, opts);
        return (await ethers.getContractAt("Asset", assetAddress));
      }
    } catch (_) {}
  }
  throw new Error("Asset creation transaction failed.");
}

/**
 * Creates an AssetTransferable.
 * An asset has to be created before the crowdfunding campaign with the predefined token supply.
 * The whole supply is automatically owned by the token creator.
 *
 * @param from Creator's signer object
 * @param issuer Asset's issuer contract instance
 * @param initialTokenSupply Total number of tokens to be created. Not changeable afterwards.
 * @param whitelistRequiredForTransfer If set to true, tokens will be transferable only between the whitelisted addresses
 * @param name Asset token name (For example APPLE INC.)
 * @param symbol Asset token symbol/ticker (For example APPL)
 * @param info Asset info ipfs hash providing more than just a name and the ticker (if necessary)
 * @param assetTransferableFactory AssetTransferable factory contract (predeployed and sitting at well known address)
 * @returns Contract instance of the deployed asset token, already connected to the owner's signer object
 */
 export async function createAssetTransferable(
  owner: String,
  issuer: Contract,
  mappedName: String,
  initialTokenSupply: Number,
  whitelistRequiredForRevenueClaim: boolean,
  whitelistRequiredForLiquidationClaim: boolean,
  name: String,
  symbol: String,
  info: String,
  assetTransferableFactory: Contract,
  nameRegistry: Contract,
  apxRegistry: Contract,
  opts?: { logOutput: boolean }
): Promise<Contract> {
  const createAssetTx = await assetTransferableFactory.create([
      owner,
      issuer.address,
      apxRegistry.address,
      mappedName,
      nameRegistry.address,
      ethers.utils.parseEther(initialTokenSupply.toString()),
      whitelistRequiredForRevenueClaim,
      whitelistRequiredForLiquidationClaim,
      name,
      symbol,
      info
    ]
  );
  const receipt = await ethers.provider.waitForTransaction(createAssetTx.hash);
  for (const recLog of receipt.logs) {
    try {
      const parsedLog = assetTransferableFactory.interface.parseLog(recLog);
      if (parsedLog.name == "AssetTransferableCreated") {
        const ownerAddress = parsedLog.args.creator;
        const assetAddress = parsedLog.args.asset;
        log(`\nAssetTransferable deployed\n\tAt address: ${assetAddress}\n\tOwner: ${ownerAddress}`, opts);
        return (await ethers.getContractAt("AssetTransferable", assetAddress));
      }
    } catch (_) {}
  }
  throw new Error("AssetTransferable creation transaction failed.");
}


/**
 * Creates an AssetTransferable.
 * An asset has to be created before the crowdfunding campaign with the predefined token supply.
 * The whole supply is automatically owned by the token creator.
 *
 * @param from Creator's signer object
 * @param issuer Asset's issuer contract instance
 * @param initialTokenSupply Total number of tokens to be created. Not changeable afterwards.
 * @param whitelistRequiredForTransfer If set to true, tokens will be transferable only between the whitelisted addresses
 * @param name Asset token name (For example APPLE INC.)
 * @param symbol Asset token symbol/ticker (For example APPL)
 * @param info Asset info ipfs hash providing more than just a name and the ticker (if necessary)
 * @param assetTransferableFactory AssetTransferable factory contract (predeployed and sitting at well known address)
 * @returns Contract instance of the deployed asset token, already connected to the owner's signer object
 */
 export async function createAssetSimple(
  owner: String,
  issuer: Contract,
  mappedName: String,
  initialTokenSupply: Number,
  name: String,
  symbol: String,
  info: String,
  assetSimpleFactory: Contract,
  nameRegistry: Contract,
  opts?: { logOutput: boolean }
): Promise<Contract> {
  const createAssetTx = await assetSimpleFactory.create([
      owner,
      issuer.address,
      mappedName,
      nameRegistry.address,
      ethers.utils.parseEther(initialTokenSupply.toString()),
      name,
      symbol,
      info
    ]
  );
  const receipt = await ethers.provider.waitForTransaction(createAssetTx.hash);
  for (const recLog of receipt.logs) {
    try {
      const parsedLog = assetSimpleFactory.interface.parseLog(recLog);
      if (parsedLog.name == "AssetSimpleCreated") {
        const ownerAddress = parsedLog.args.creator;
        const assetAddress = parsedLog.args.asset;
        log(`\nAssetSimple deployed\n\tAt address: ${assetAddress}\n\tOwner: ${ownerAddress}`, opts);
        return (await ethers.getContractAt("AssetSimple", assetAddress));
      }
    } catch (_) {}
  }
  throw new Error("AssetSimple creation transaction failed.");
}

/**
 * Creates the crowdfunding campaign contract.
 * For the crowdfunding campaign to be considered active, the creator has to transfer tokens
 * to be sold to the address of this contract, and then call the approveCampaign() function on the
 * Issuer contract.
 *
 * @param from Creator's signer object
 * @param asset Asset contract instance whose tokens are to be sold through this crowdfunding campaign
 * @param initialPricePerToken Price per token (in stablecoin)
 * @param softCap Minimum funds to be raised (in stablecoin) for the campaigng to succeed
 * @param whitelistRequired Set to true to allow only whitelisted (kyc) wallets to invest.
 * @param info Campaign info ipfs hash describing this campaign.
 * @param cfManagerFactory CfManager factory contract (predeployed and sitting at well known address)
 * @returns Contract instance of the deployed crowdfunding manager, already connected to the owner's signer object
 */
export async function createCfManager(
  owner: String,
  mappedName: String,
  asset: Contract,
  pricePerToken: Number,
  softCap: Number,
  minInvestment: Number,
  maxInvestment: Number,
  whitelistRequired: boolean,
  info: String,
  cfManagerFactory: Contract,
  nameRegistry: Contract,
  opts?: { logOutput: boolean }
): Promise<Contract> {
  const issuer = await ethers.getContractAt("Issuer", 
    (await asset.commonState()).issuer
  );
  const stablecoinAddress = (await issuer.commonState()).stablecoin;
  const stablecoin = await ethers.getContractAt("USDC", stablecoinAddress);
  const cfManagerTx = await cfManagerFactory.create(
    owner,
    mappedName,
    asset.address,
    pricePerToken,
    await parseStablecoin(softCap, stablecoin),
    await parseStablecoin(minInvestment, stablecoin),
    await parseStablecoin(maxInvestment, stablecoin),
    whitelistRequired,
    info,
    nameRegistry.address
  );
  const receipt = await ethers.provider.waitForTransaction(cfManagerTx.hash);
  for (const recLog of receipt.logs) {
    try {
      const parsedLog = cfManagerFactory.interface.parseLog(recLog);
      if (parsedLog.name == "CfManagerSoftcapCreated") {
        const ownerAddress = parsedLog.args.creator;
        const cfManagerAddress = parsedLog.args.cfManager;
        const assetAddress = parsedLog.args.asset;
        log(`\nCrowdfunding Campaign deployed\n\tAt address: ${cfManagerAddress}\n\tOwner: ${ownerAddress}\n\tAsset: ${assetAddress}`, opts);
        return (await ethers.getContractAt("CfManagerSoftcap", cfManagerAddress));
      }
    } catch (_) {}
  }
  throw new Error("Crowdfunding Campaign creation transaction failed.");
}

/**
 * Invests some amount of the stablecoin.
 * The stablecoin to be used was fetched earlier by reading the asset's issuer configuration.
 *
 * Two transactions involved here:
 *  1) Approve CfManager to spend your funds
 *  2) Call the invest() function on the CfManager
 *
 * @param investor Investor signer object
 * @param cfManager CfManager contract instance
 * @param stablecoin Stablecoin contract instance to be used for payment
 * @param amount Amount of the stablecoin to be invested
 */
export async function invest(investor: Signer, cfManager: Contract, stablecoin: Contract, amount: Number) {
  const amountWei = await parseStablecoin(amount, stablecoin);
  await stablecoin.connect(investor).approve(cfManager.address, amountWei);
  await cfManager.connect(investor).invest(amountWei);
}

/**
 * Invests some amount of the stablecoin.
 * The stablecoin to be used was fetched earlier by reading the asset's issuer configuration.
 *
 * Two transactions involved here:
 *  1) Approve CfManager to spend your funds
 *  2) Call the invest() function on the CfManager
 *
 * @param investor Investor signer object
 * @param cfManager CfManager contract instance
 * @param stablecoin Stablecoin contract instance to be used for payment
 * @param amount Amount of the stablecoin to be invested
 */
 export async function investForBeneficiary(spender: Signer, beneficiary: Signer, cfManager: Contract, stablecoin: Contract, amount: Number, caller: Signer = ethers.provider.getSigner()) {
  const amountWei = await parseStablecoin(amount, stablecoin);
  const beneficiaryAddress = await beneficiary.getAddress();
  const spenderAddress = await spender.getAddress();
  await stablecoin.connect(spender).approve(cfManager.address, amountWei);
  await cfManager.connect(caller).investForBeneficiary(spenderAddress, beneficiaryAddress, amountWei);
}

/**
 * Will cancel the full amount invested in the project. Transaction will return
 * all of the invested funds to the investor's wallet. Can only be called by the
 * investor who has placed an investment in the campaign, and the campaign was not yet
 * finalized.
 *
 * @param investor Investor signer object
 * @param cfManager CfManager contract instance
 */
export async function cancelInvest(investor: Signer, cfManager: Contract) {
  await cfManager.connect(investor).cancelInvestment();
}

/**
 * Transfers claimable tokens to the investors wallet.
 * Can only be called if the investor has actually invested in the campaign
 * and only after the campaign owner has finalized the campaign.
 *
 * @param investor Investor signer object
 * @param cfManager CfManager contract instance
 */
export async function claimInvestment(investor: Signer, cfManager: Contract) {
  const investorAddress = await investor.getAddress();
  await cfManager.connect(investor).claim(investorAddress);
}

/**
 * Finalizes active crowdfunding campaign.
 * Can only be called by the campaign owner if the soft cap has been reached.
 * This transaction will transfer all of the funds raised to the owner's wallet.
 * If some of the tokens were not sold they are also returned to the owner's wallet
 * in the same transaction.
 *
 * @param owner CfManager owner signer object
 * @param cfManager CfManager contract instance
 */
export async function finalizeCampaign(owner: Signer, cfManager: Contract) {
  await cfManager.connect(owner).finalize();
}

/**
 * Cancels active crowdfunding campaign.
 * Can only be cancelled by the campaign owner, if it was not finalized before.
 *
 * @param owner CfManager contract owner signer object
 * @param cfManager CfManager contract instance
 */
export async function cancelCampaign(owner: Signer, cfManager: Contract) {
  await cfManager.connect(owner).cancelCampaign();
}

/**
 * Will update info hash on the target object.
 * Can only be called by the contract owner.
 *
 * @param owner Contract owner signer object
 * @param contract Must be one of: Issuer, CfManager, Asset, AssetTransferable
 */
export async function setInfo(owner: Signer, contract: Contract, infoHash: String) {
  await contract.connect(owner).setInfo(infoHash);
}

/**
 * ApxAssetRegistry related functions. Handled by the APX protocol!
 */
export async function registerAsset(assetManager: Signer, apxRegistry: Contract, original: String, mirrored: String) {
  await apxRegistry.connect(assetManager).registerAsset(original, mirrored, true);
}
export async function updateState(assetManager: Signer, apxRegistry: Contract, asset: String, state: boolean) {
  await apxRegistry.connect(assetManager).updateState(asset, state);
}
export async function updatePrice(priceManager: Signer, apxRegistry: Contract, asset: Contract, price: Number, expiry: Number) {
  const capturedSupply = await asset.totalSupply();
  await apxRegistry.connect(priceManager).updatePrice(asset.address, price, expiry, capturedSupply);
}

/**
 * CampaignFeeManager related functions.
 */
export async function setDefaultFee(feeManager: Contract, numerator: Number, denominator: Number) {
  await feeManager.setDefaultFee(true, numerator, denominator);
}

export async function setFeeForCampaign(feeManager: Contract, campaign: String, numerator: Number, denominator: Number) {
  await feeManager.setCampaignFee(campaign, true, numerator, denominator);
}

/**
 * Liquidation functions.
 */
export async function liquidate(liquidator: Signer, asset: Contract, stablecoin: Contract, liquidationFunds: Number) {
  const liquidatorAddress = await liquidator.getAddress();
  const liquidatorOwnedAssetTokens = await asset.balanceOf(liquidatorAddress);
  const liquidationFundsWei = await parseStablecoin(liquidationFunds, stablecoin);
  await asset.connect(liquidator).approve(asset.address, liquidatorOwnedAssetTokens);
  await stablecoin.connect(liquidator).approve(asset.address, liquidationFundsWei);
  await asset.connect(liquidator).liquidate();
}
export async function claimLiquidationShare(investor: Signer, asset: Contract) {
  const investorAddress = await investor.getAddress();
  const tokenAmount = await asset.balanceBeforeLiquidation(investorAddress);
  await asset.connect(investor).approve(asset.address, tokenAmount);
  await asset.claimLiquidationShare(investorAddress);
}

/**
 * Query contract for complete edit history.
 * Every new info update is a new hash stored in the contract state together with the timestamp.
 * 
 * @param contract Must be one of: Issuer, CfManager, Asset
 * @returns Returns array of all the info strings (with timestamps) with the last one being the active info hash.
 */
export async function getInfoHistory(contract: Contract): Promise<object> {
  return contract.getInfoHistory();
}

/**
 *
 * @param contract Issuer contract instance
 * @returns State object
 *
 * Example response array (ethersjs):
 *
 *   [
 *    id: BigNumber { _hex: '0x00', _isBigNumber: true },
 *    owner: '0x70997970C51812dc3A010C7d01b50e0d17dc79C8',
 *    stablecoin: '0x5FbDB2315678afecb367f032d93F642f64180aa3',
 *    walletApprover: '0x976EA74026E726554dB657fA54763abd0C3a0aa9',
 *    info: 'updated-issuer-info-ipfs-hash'
 *   ]
 */
export async function getIssuerState(contract: Contract): Promise<String> {
  return contract.getState();
}

/**
 *
 * @param contract Asset contract instance
 * @returns State object
 *
 * Example response array (ethersjs):
 *
 *  [
 *   id: BigNumber { _hex: '0x00', _isBigNumber: true },
 *   owner: '0x70997970C51812dc3A010C7d01b50e0d17dc79C8',
 *   mirroredToken: '0x0000000000000000000000000000000000000000',
 *   initialTokenSupply: BigNumber { _hex: '0xd3c21bcecceda1000000', _isBigNumber: true },
 *   whitelistRequiredForTransfer: true,
 *   issuer: '0xCafac3dD18aC6c6e92c921884f9E4176737C052c',
 *   info: 'updated-asset-info-hash',
 *   name: 'Test Asset',
 *   symbol: 'TSTA'
 *  ]
 *
 */
export async function getAssetState(contract: Contract): Promise<object> {
  return contract.getState();
}

/**
 *
 * @param contract CfManager contract instance
 * @returns State object
 *
 * Example response array (ethersjs):
 *
 *   [
 *    id: BigNumber { _hex: '0x00', _isBigNumber: true },
 *    owner: '0x70997970C51812dc3A010C7d01b50e0d17dc79C8',
 *    asset: '0x75537828f2ce51be7289709686A69CbFDbB714F1',
 *    tokenPrice: BigNumber { _hex: '0x2710', _isBigNumber: true },
 *    softCap: BigNumber { _hex: '0x54b40b1f852bda000000', _isBigNumber: true },
 *    whitelistRequired: true,
 *    finalized: true,
 *    cancelled: false,
 *    totalClaimableTokens: BigNumber { _hex: '0x54b40b1f852bda000000', _isBigNumber: true },
 *    totalInvestorsCount: BigNumber { _hex: '0x01', _isBigNumber: true },
 *    totalClaimsCount: BigNumber { _hex: '0x01', _isBigNumber: true },
 *    totalFundsRaised: BigNumber { _hex: '0x58f03ee118a13e800000', _isBigNumber: true },
 *    info: 'updated-campaign-info-hash'
 *   ]
 */
export async function getCrowdfundingCampaignState(contract: Contract): Promise<object> {
  return contract.getState();
}

/**
 * @param issuerFactory Predeployed Issuer factory instance
 * @returns Array of issuer states
 */
export async function fetchIssuerInstances(issuerFactory: Contract): Promise<object> {
  const instances = await issuerFactory.getInstances();
  const mappedInstances = await Promise.all(instances.map(async (instanceAddress: string) => {
    const instance = await ethers.getContractAt("Issuer", instanceAddress);
    return instance.getState();
  }));
  return mappedInstances;
}

/**
 * @param assetFactory Predeployed Asset factory instance
 * @returns Array of asset states
 */
export async function fetchAssetInstances(assetFactory: Contract, assetType: string): Promise<object> {
  const instances = await assetFactory.getInstances();
  const mappedInstances = await Promise.all(instances.map(async (instanceAddress: string) => {
    const instance = await ethers.getContractAt(assetType, instanceAddress);
    return instance.getState();
  }));
  return mappedInstances;
}

/**
 * @param assetFactory Predeployed Asset factory instance
 * @param issuer Filter assets by this issuer
 * @returns Array of asset states
 */
export async function fetchAssetInstancesForIssuer(assetFactory: Contract, assetType: string, issuer: Contract): Promise<object> {
  const instances = await assetFactory.getInstancesForIssuer(issuer.address);
  const mappedInstances = await Promise.all(instances.map(async (instanceAddress: string) => {
    const instance = await ethers.getContractAt(assetType, instanceAddress);
    return instance.getState();
  }));
  return mappedInstances;
}

/**
 * @param cfManagerFactory Predeployed CfManager factory instance
 * @returns Array of crowdfunding campaign states
 */
export async function fetchCrowdfundingInstances(cfManagerFactory: Contract, campaignType: string): Promise<object> {
  const instances = await cfManagerFactory.getInstances();
  const mappedInstances = await Promise.all(instances.map(async (instanceAddress: string) => {
    const instance = await ethers.getContractAt(campaignType, instanceAddress);
    return instance.getState();
  }));
  return mappedInstances;
}

/**
 * @param cfManagerFactory Predeployed CfManager factory instance
 * @param issuer Filter campaigns by this issuer
 * @returns Array of crowdfunding campaign states
 */
export async function fetchCrowdfundingInstancesForIssuer(cfManagerFactory: Contract, campaignType: string, issuer: Contract): Promise<object> {
  const instances = await cfManagerFactory.getInstancesForIssuer(issuer.address);
  const mappedInstances = await Promise.all(instances.map(async (instanceAddress: string) => {
    const instance = await ethers.getContractAt(campaignType, instanceAddress);
    return instance.getState();
  }));
  return mappedInstances;
}

/**
 * @param cfManagerFactory Predeployed CfManager factory instance
 * @param asset Filter campaigns by this asset
 * @returns Array of crowdfunding campaign states
 */
export async function fetchCrowdfundingInstancesForAsset(cfManagerFactory: Contract, campaignType: string, asset: Contract): Promise<object> {
  const instances = await cfManagerFactory.getInstancesForAsset(asset.address);
  const mappedInstances = await Promise.all(instances.map(async (instanceAddress: string) => {
    const instance = await ethers.getContractAt(campaignType, instanceAddress);
    return instance.getState();
  }));
  return mappedInstances;
}

/**
 * @param issuerFactory Predeployed Issuer factory instance
 * @param id Issuer id
 * @returns issuer state
 */
export async function fetchIssuerStateById(issuerFactory: Contract, id: Number): Promise<object> {
  const instanceAddress = await issuerFactory.instances(id);
  const instance = await ethers.getContractAt("Issuer", instanceAddress);
  return instance.getState();
}

/**
 * @param cfManagerFactory Predeployed CfManager factory instance
 * @param id Crowdfunding campaign id
 * @returns Crowdfunding campaign state
 */
export async function fetchCampaignStateById(cfManagerFactory: Contract, campaignType: string, id: Number): Promise<object> {
  const instanceAddress = await cfManagerFactory.instances(id);
  const instance = await ethers.getContractAt(campaignType, instanceAddress);
  return instance.getState();
}

/**
 * @param assetFactory Predeployed Asset factory instance
 * @param id Asset id
 * @returns Asset state
 */
export async function fetchAssetStateById(assetFactory: Contract, assetType: string, id: Number): Promise<object> {
  const instanceAddress = await assetFactory.instances(id);
  const instance = await ethers.getContractAt(assetType, instanceAddress);
  return instance.getState();
}

/**
 * Fetches transaction history for given user wallet and issuer instance.
 * To calculate this, one must fetch all the instances of the following contracts for given issuer:
 * -> Asset (for asset token transfers, if any)
 * -> CfManagerSoftcap (for investment, cancel investment and claim tokens transactions)
 * Then after all the contract instances have been fetched, we scan for specific events and filter
 * by the user's wallet.
 *
 * @param wallet User wallet address
 * @param issuer Issuer contract instance
 * @param cfManagerFactory Predeployed CfManager contract factory
 * @param assetFactory Predeployed Asset contract factory
 */
export async function fetchTxHistory(
  wallet: string,
  issuer: Contract,
  cfManagerFactory: Contract,
  campaignType: string,
  assetFactory: Contract,
  assetType: string
) {
  const assetTransactions = await filters.getAssetTransactions(wallet, issuer, assetFactory, assetType);;
  const crowdfundingTransactions = await filters.getCrowdfundingCampaignTransactions(wallet, issuer, cfManagerFactory, campaignType);
  // TODO: add PayoutManager transactions to cover the revenue share payout case !
  const transactions = assetTransactions.concat(crowdfundingTransactions);
  return transactions.sort((a, b) => (a.timestamp < b.timestamp) ? -1 : 1);
}

/**
 * @param issuer Issuer contract instance
 * @returns Array of issuer wallet records
 *
 * Example response array (ethers.js)
 *
 *   [
 *     [
 *       wallet: '0x90F79bf6EB2c4f870365E785982E1f101E93b906',
 *       whitelisted: true
 *     ],
 *     [
 *       wallet: '0x15d34AAf54267DB7D7c367839AAf71A00a2C6A65',
 *       whitelisted: true
 *     ]
 *   ]
 */
export async function fetchWalletRecords(issuer: Contract): Promise<Array<object>> {
  return issuer.getWalletRecords();
}

/**
 * @param queryService QueryService contract instance
 * @param cfManagerFactory CfManagerFactory contract instance
 * @param issuer Issuer contract instance
 * @returns Array of campaign states for given issuer
 */
export async function queryCampaignsForIssuer(
  queryService: Contract,
  cfManagerFactory: Contract,
  issuer: Contract,
  nameRegistry: Contract
): Promise<Array<Object>> {
  return queryService.getCampaignsForIssuer(issuer.address, [ cfManagerFactory.address ], nameRegistry.address);
}

export async function queryCampaignsForIssuerInvestor(
  queryService: Contract,
  cfManagerFactory: Contract,
  issuer: Contract,
  investor: String,
  nameRegistry: Contract
): Promise<Array<Object>> {
  return queryService.getCampaignsForIssuerInvestor(issuer.address, investor, [ cfManagerFactory.address ], nameRegistry.address);
}

export async function queryIssuerForAssetBalances(
  queryService: Contract,
  issuer: Contract,
  investor: string,
  assetFactories: string[],
  campaignFactories: string[]
): Promise<AssetBalance[]> {
  return queryService.getAssetBalancesForIssuer(issuer.address, investor, assetFactories, campaignFactories)
}

interface AssetCommonState {
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
interface AssetBalance {
  contractAddress: string;
  decimals: number;
  name: string;
  symbol: string;
  balance: BigNumber;
  assetCommonState: AssetCommonState
}

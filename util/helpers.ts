import { ethers } from "hardhat";
import { Contract, Signer } from "ethers";
import * as filters from "./filters";

export async function deployStablecoin(deployer: Signer, supply: string, confirmations: number = 1): Promise<Contract> {
  const supplyWei = ethers.utils.parseEther(supply);
  const USDC = await ethers.getContractFactory("USDC", deployer);
  const stablecoin = await USDC.deploy(supplyWei);
  await ethers.provider.waitForTransaction(stablecoin.deployTransaction.hash, confirmations)
  console.log(`\nStablecoin deployed\n\tAt address: ${stablecoin.address}`);
  return stablecoin;
}

export async function deployApxRegistry(deployer: Signer, masterOwner: String, assetManager: String, priceManager: String, confirmations: number = 1): Promise<Contract> {
  const ApxRegistry = await ethers.getContractFactory("ApxAssetsRegistry", deployer);
  const apxRegistry = await ApxRegistry.deploy(masterOwner, assetManager, priceManager);
  await ethers.provider.waitForTransaction(apxRegistry.deployTransaction.hash, confirmations)
  console.log(`\nApxRegistry deployed\n\tAt address: ${apxRegistry.address}`);
  return apxRegistry;
}

export async function deployNameRegistry(deployer: Signer, masterOwner: String, factories: String[], confirmations: number = 1): Promise<Contract> {
  const NameRegistry = await ethers.getContractFactory("NameRegistry", deployer);
  const isWhitelisted: Boolean[] = factories.map(_ => true);
  const nameRegistry = await NameRegistry.deploy(masterOwner, factories, isWhitelisted);
  await ethers.provider.waitForTransaction(nameRegistry.deployTransaction.hash, confirmations)
  console.log(`\nNameRegistry deployed\n\tAt address: ${nameRegistry.address}`);
  return nameRegistry;
}

export async function deployFactories(deployer: Signer, confirmations: number = 1): Promise<Contract[]> {
  return [
    await deployIssuerFactory(deployer, confirmations),
    await deployAssetFactory(deployer, confirmations),
    await deployAssetTransferableFactory(deployer, confirmations),
    await deployCfManagerFactory(deployer, confirmations),
    await deploySnapshotDistributorFactory(deployer, confirmations)
  ];
}

export async function deployServices(deployer: Signer, masterWalletApprover: string, rewardPerApprove: string): Promise<Contract[]> {
  return [
    await deployWalletApproverService(deployer, masterWalletApprover, rewardPerApprove),
    await deployDeployerService(deployer),
    await deployQueryService(deployer)
  ];
}

export async function deployWalletApproverService(
  deployer: Signer,
  masterWalletApprover: string,
  rewardPerApproval: string,
  confirmations: number = 1
): Promise<Contract> {
  const WalletApproverService = await ethers.getContractFactory("WalletApproverService", deployer);
  const rewardPerApprovalWei = ethers.utils.parseEther(rewardPerApproval);
  const walletApproverService = await WalletApproverService.deploy(
    masterWalletApprover, [ ], rewardPerApprovalWei
  );
  await ethers.provider.waitForTransaction(walletApproverService.deployTransaction.hash, confirmations)
  console.log(`\nWallet approver service deployed\n\tAt address: ${walletApproverService.address}\n\tReward per approval: ${rewardPerApproval} ETH`);
  return walletApproverService;
}

export async function deployDeployerService(deployer: Signer, confirmations: number = 1): Promise<Contract> {
  const DeployerService = await ethers.getContractFactory("DeployerService", deployer);
  const deployerService = await DeployerService.deploy();
  await ethers.provider.waitForTransaction(deployerService.deployTransaction.hash, confirmations)
  console.log(`\nDeployer service deployed\n\tAt address: ${deployerService.address}`);
  return deployerService;
}

export async function deployQueryService(deployer: Signer, confirmations: number = 1): Promise<Contract> {
  const QueryService = await ethers.getContractFactory("QueryService", deployer);
  const queryService = await QueryService.deploy();
  console.log(`\nQuery service deployed\n\tAt address: ${queryService.address}`);
  return queryService;
}

export async function deployIssuerFactory(deployer: Signer, confirmations: number = 1): Promise<Contract> {
  const IssuerFactory = await ethers.getContractFactory("IssuerFactory", deployer);
  const issuerFactory = await IssuerFactory.deploy();
  await ethers.provider.waitForTransaction(issuerFactory.deployTransaction.hash, confirmations)
  console.log(`\nIssuerFactory deployed\n\tAt address: ${issuerFactory.address}`);
  return issuerFactory;
}

export async function deployAssetFactory(deployer: Signer, confirmations: number = 1): Promise<Contract> {
  const AssetDeployer = await ethers.getContractFactory("AssetDeployer", deployer);
  const assetDeployer = await AssetDeployer.deploy();
  const AssetFactory = await ethers.getContractFactory("AssetFactory", deployer);
  const assetFactory = await AssetFactory.deploy(assetDeployer.address);
  await ethers.provider.waitForTransaction(assetFactory.deployTransaction.hash, confirmations)
  console.log(`\nAssetFactory deployed\n\tAt address: ${assetFactory.address}`);
  return assetFactory;
}

export async function deployAssetSimpleFactory(deployer: Signer, confirmations: number = 1): Promise<Contract> {
  const AssetFactory = await ethers.getContractFactory("AssetSimpleFactory", deployer);
  const assetFactory = await AssetFactory.deploy();
  await ethers.provider.waitForTransaction(assetFactory.deployTransaction.hash, confirmations)
  console.log(`\nAssetSimpleFactory deployed\n\tAt address: ${assetFactory.address}`);
  return assetFactory;
}

export async function deployAssetTransferableFactory(deployer: Signer, confirmations: number = 1): Promise<Contract> {
  const AssetTransferableDeployer = await ethers.getContractFactory("AssetTransferableDeployer", deployer);
  const assetTransferableDeployer = await AssetTransferableDeployer.deploy();
  const AssetTransferableFactory = await ethers.getContractFactory("AssetTransferableFactory", deployer);
  const assetTransferableFactory = await AssetTransferableFactory.deploy(assetTransferableDeployer.address);
  await ethers.provider.waitForTransaction(assetTransferableFactory.deployTransaction.hash, confirmations)
  console.log(`\nAssetTransferableFactory deployed\n\tAt address: ${assetTransferableFactory.address}`);
  return assetTransferableFactory;
}

export async function deployCfManagerFactory(deployer: Signer, confirmations: number = 1): Promise<Contract> {
  const CfManagerFactory = await ethers.getContractFactory("CfManagerSoftcapFactory", deployer);
  const cfManagerFactory = await CfManagerFactory.deploy();
  await ethers.provider.waitForTransaction(cfManagerFactory.deployTransaction.hash, confirmations)
  console.log(`\nCfManagerFactory deployed\n\tAt address: ${cfManagerFactory.address}`);
  return cfManagerFactory;
}

export async function deployCfManagerVestingFactory(deployer: Signer, confirmations: number = 1): Promise<Contract> {
  const CfManagerVestingFactory = await ethers.getContractFactory("CfManagerSoftcapVestingFactory", deployer);
  const cfManagerFactory = await CfManagerVestingFactory.deploy();
  await ethers.provider.waitForTransaction(cfManagerFactory.deployTransaction.hash, confirmations)
  console.log(`\nCfManagerVestingFactory deployed\n\tAt address: ${cfManagerFactory.address}`);
  return cfManagerFactory;
}

export async function deploySnapshotDistributorFactory(deployer: Signer, confirmations: number = 1): Promise<Contract> {
  const SnapshotDistributorFactory = await ethers.getContractFactory("SnapshotDistributorFactory", deployer);
  const snapshotDistributorFactory = await SnapshotDistributorFactory.deploy();
  await ethers.provider.waitForTransaction(snapshotDistributorFactory.deployTransaction.hash, confirmations)
  console.log(`\nSnapshotDistributorFactory deployed\n\tAt address: ${snapshotDistributorFactory.address}`);
  return snapshotDistributorFactory;
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
  nameRegistry: Contract
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
  console.log("issuer deployed, scanning for events", receipt)
  for (const log of receipt.logs) {
    try {
      const parsedLog = issuerFactory.interface.parseLog(log);
      console.log("parsedLog", parsedLog);
      if (parsedLog.name == "IssuerCreated") {
        const ownerAddress = parsedLog.args.creator;
        console.log("parsed creator", ownerAddress);
        const issuerAddress = parsedLog.args.issuer;
        console.log(`\nIssuer deployed\n\tAt address: ${issuerAddress}\n\tOwner: ${ownerAddress}`);
        return (await ethers.getContractAt("Issuer", issuerAddress));
      }
    } catch (_) {}
  }
  throw new Error("Issuer creation transaction failed.");
}

/**
 * Creates an Asset which is basically an ERC-20 token with the possibility 
 * of taking snapshots to support revenue distribution functionality.
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
 * @param assetFactory Asset factory contract (predeployed and sitting at well known address)
 * @returns Contract instance of the deployed asset token, already connected to the owner's signer object
 */
export async function createAsset(
  owner: String,
  issuer: Contract,
  mappedName: String,
  initialTokenSupply: Number,
  whitelistRequiredForRevenueClaim: boolean,
  whitelistRequiredForLiquidationClaim: boolean,
  name: String,
  symbol: String,
  info: String,
  assetFactory: Contract,
  nameRegistry: Contract,
  apxRegistry: Contract
): Promise<Contract> {
  const createAssetTx = await assetFactory.create(
    owner,
    issuer.address,
    apxRegistry.address,
    nameRegistry.address,
    mappedName,
    ethers.utils.parseEther(initialTokenSupply.toString()),
    whitelistRequiredForRevenueClaim,
    whitelistRequiredForLiquidationClaim,
    name,
    symbol,
    info
  );
  const receipt = await ethers.provider.waitForTransaction(createAssetTx.hash);
  for (const log of receipt.logs) {
    try {
      const parsedLog = assetFactory.interface.parseLog(log);
      if (parsedLog.name == "AssetCreated") {
        const ownerAddress = parsedLog.args.creator;
        const assetAddress = parsedLog.args.asset;
        console.log(`\nAsset deployed\n\tAt address: ${assetAddress}\n\tOwner: ${ownerAddress}`);
        return (await ethers.getContractAt("Asset", assetAddress));
      }
    } catch (_) {}
  }
  throw new Error("Asset creation transaction failed.");
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
  nameRegistry: Contract
): Promise<Contract> {
  const cfManagerTx = await cfManagerFactory.create(
    owner,
    mappedName,
    asset.address,
    pricePerToken,
    ethers.utils.parseEther(softCap.toString()),
    ethers.utils.parseEther(minInvestment.toString()),
    ethers.utils.parseEther(maxInvestment.toString()),
    whitelistRequired,
    info,
    nameRegistry.address
  );
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
    } catch (_) {}
  }
  throw new Error("Crowdfunding Campaign creation transaction failed.");
}

/**
 * Creates snapshot distributor to be used later for distributing revenue to the token holders.
 * 
 * @param from Revenue distributor signer object
 * @param asset Asset contract instance whose token holders are to receive payments
 * @param info SnapshotDistributor info ipfs-hash
 * @param snapshotDistributorFactory SnapshotDistributor factory contract (predeployed and sitting at well known address)
 * @returns Contract instance of the deployed snapshot distributor, already connected to the owner's signer object 
 */
export async function createSnapshotDistributor(
  owner: String,
  mappedName: String,
  asset: Contract,
  info: String,
  snapshotDistributorFactory: Contract,
  nameRegistry: Contract
 ): Promise<Contract> {
  const snapshotDistributorTx = await snapshotDistributorFactory.create(owner, mappedName, asset.address, info, nameRegistry.address);
  const receipt = await ethers.provider.waitForTransaction(snapshotDistributorTx.hash);
  for (const log of receipt.logs) {
    try {
      const parsedLog = snapshotDistributorFactory.interface.parseLog(log);
      if (parsedLog.name == "SnapshotDistributorCreated") {
        const owner = parsedLog.args.creator;
        const snapshotDistributorAddress = parsedLog.args.distributor;
        const assetAddress = parsedLog.args.asset;
        console.log(`\nSnapshotDistributor deployed\n\tAt address: ${snapshotDistributorAddress}\n\tFor Asset: ${assetAddress}\n\tOwner: ${owner}`);
        return ethers.getContractAt("SnapshotDistributor", snapshotDistributorAddress);
      }
    } catch (_) {}
  }
  throw new Error(" creation transaction failed.");
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
  const amountWei = ethers.utils.parseEther(amount.toString());
  await stablecoin.connect(investor).approve(cfManager.address, amountWei);
  await cfManager.connect(investor).invest(amountWei);
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
 * Distributes revenue to the token holders, proportional to the amount of the tokens 
 * owned at the moment of the execution of this transaction. If the token ownership structure changes
 * after this transaction has been processed, it will not impact the distribution because the ownership
 * structure snapshot has been made when the revenue was distributed.
 * 
 * Revenue distribution goes through the SnapshotDistributor contract, created by the SnapshotDistributorFactory.
 * One snapshot distributor can be used for multiple payouts (say yearly shareholder dividend payout).
 * 
 * If the SnapshotDistributor contract exists, the actual payout process is made of two steps:
 *  1) approve the snapshot distributor contract to spend revenue amount (in given stablecoin)
 *  2) call the createPayout() function on the SnapshotDistributor contract
 * 
 * createPayout() function will take the snapshot of the token holders structure and distribute revenue accordingly.
 * createPayout() function also takes the payment description as parameter, if there is any info to be provided for 
 *                the payment batch (for example "WindFarm Q3/2021 revenue")
 * 
 * @param owner Payment creator signer object
 * @param snapshotDistributor SnapshotDistributor contract instance used for handling the payouts. Has to be created before calling this function.
 * @param stablecoin Stablecoin contract instance to be used as the payment method
 * @param amount Amount (in stablecoin) to be distributed as revenue
 * @param payoutDescription Description for this revenue payout
 */
export async function createPayout(owner: Signer, snapshotDistributor: Contract, stablecoin: Contract, amount: Number, payoutDescription: String) {
  const amountWei = ethers.utils.parseEther(amount.toString());
  await stablecoin.connect(owner).approve(snapshotDistributor.address, amountWei);
  await snapshotDistributor.connect(owner).createPayout(payoutDescription, stablecoin.address, amountWei, []);
}

/**
 * Claims revenue for given investor, SnapshotDistributor contract and snapshot id.
 * SnapshotId is important since one SnapshotDistributor contract can handle multiple
 * payouts (say yearly dividend payout). Every time new revenue is transferred to the
 * manager contract -> new snapshopt id is created with id being an auto increment (starts from 1).
 * 
 * @param investor Investor signer object
 * @param snapshotDistributor Contract instance handling payouts for one Asset
 * @param snapshotId Snapshot id of the payout
 */
export async function claimRevenue(investor: Signer, snapshotDistributor: Contract, snapshotId: Number) {
  const investorAddress = await investor.getAddress();
  await snapshotDistributor.connect(investor).release(investorAddress, snapshotId);
}

/**
 * Will update info hash on the target object.
 * Can only be called by the contract owner.
 * 
 * @param owner Contract owner signer object
 * @param contract Must be one of: Issuer, CfManager, Asset, AssetTransferable, SnapshotDistributor
 */
export async function setInfo(owner: Signer, contract: Contract, infoHash: String) {
  await contract.connect(owner).setInfo(infoHash);
}

export async function setChildChainManager(owner: Signer, contract: Contract, manager: String) {
  await contract.connect(owner).setChildChainManager(manager);
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
 * Liquidation functions.
 */
export async function liquidate(liquidator: Signer, asset: Contract, stablecoin: Contract, liquidationFunds: Number) {
  const liquidatorAddress = await liquidator.getAddress();
  const liquidatorOwnedAssetTokens = await asset.balanceOf(liquidatorAddress);
  const liquidationFundsWei = ethers.utils.parseEther(liquidationFunds.toString());
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
 * @param contract Must be one of: Issuer, CfManager, Asset, SnapshotDistributor
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
export async function getAssetChildChainManager(contract: Contract): Promise<string> {
  const state = await contract.getState();
  return state.childChainManager;
}
export async function getMirroredAssetChildChainManager(contract: Contract): Promise<string> {
  return contract.childChainManager();
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
 * 
 * @param contract SnapshotDistributor contract instance
 * @returns State object
 * 
 * Example response array (ethersjs):
 * 
 *   [
 *    id: BigNumber { _hex: '0x00', _isBigNumber: true },
 *    owner: '0x70997970C51812dc3A010C7d01b50e0d17dc79C8',
 *    asset: '0x75537828f2ce51be7289709686A69CbFDbB714F1',
 *    info: 'updated-payout-manager-info-hash'
 *   ]
 */
export async function getSnapshotDistributorState(contract: Contract): Promise<object> {
  return contract.commonState();
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
export async function fetchAssetInstances(assetFactory: Contract): Promise<object> {
  const instances = await assetFactory.getInstances();
  const mappedInstances = await Promise.all(instances.map(async (instanceAddress: string) => {
    const instance = await ethers.getContractAt("Asset", instanceAddress);
    return instance.getState();
  }));
  return mappedInstances;
}

/**
 * @param assetFactory Predeployed Asset factory instance
 * @param issuer Filter assets by this issuer
 * @returns Array of asset states
 */
export async function fetchAssetInstancesForIssuer(assetFactory: Contract, issuer: Contract): Promise<object> {
  const instances = await assetFactory.getInstancesForIssuer(issuer.address);
  const mappedInstances = await Promise.all(instances.map(async (instanceAddress: string) => {
    const instance = await ethers.getContractAt("Asset", instanceAddress);
    return instance.getState();
  }));
  return mappedInstances;
}

/**
 * @param cfManagerFactory Predeployed CfManager factory instance
 * @returns Array of crowdfunding campaign states
 */
export async function fetchCrowdfundingInstances(cfManagerFactory: Contract): Promise<object> {
  const instances = await cfManagerFactory.getInstances();
  const mappedInstances = await Promise.all(instances.map(async (instanceAddress: string) => {
    const instance = await ethers.getContractAt("CfManagerSoftcap", instanceAddress);
    return instance.getState();
  }));
  return mappedInstances;
}

/**
 * @param cfManagerFactory Predeployed CfManager factory instance
 * @param issuer Filter campaigns by this issuer
 * @returns Array of crowdfunding campaign states
 */
export async function fetchCrowdfundingInstancesForIssuer(cfManagerFactory: Contract, issuer: Contract): Promise<object> {
  const instances = await cfManagerFactory.getInstancesForIssuer(issuer.address);
  const mappedInstances = await Promise.all(instances.map(async (instanceAddress: string) => {
    const instance = await ethers.getContractAt("CfManagerSoftcap", instanceAddress);
    return instance.getState();
  }));
  return mappedInstances;
}

/**
 * @param cfManagerFactory Predeployed CfManager factory instance
 * @param asset Filter campaigns by this asset
 * @returns Array of crowdfunding campaign states
 */
export async function fetchCrowdfundingInstancesForAsset(cfManagerFactory: Contract, asset: Contract): Promise<object> {
  const instances = await cfManagerFactory.getInstancesForAsset(asset.address);
  const mappedInstances = await Promise.all(instances.map(async (instanceAddress: string) => {
    const instance = await ethers.getContractAt("CfManagerSoftcap", instanceAddress);
    return instance.getState();
  }));
  return mappedInstances;
}

/**
 * @param snapshotDistributorFactory Predeployed SnapshotDistributor factory instance
 * @returns Array of SnapshotDistributor states
 */
export async function fetchSnapshotDistributorInstances(snapshotDistributorFactory: Contract): Promise<object> {
  const instances = await snapshotDistributorFactory.getInstances();
  const mappedInstances = await Promise.all(instances.map(async (instanceAddress: string) => {
    const instance = await ethers.getContractAt("SnapshotDistributor", instanceAddress);
    return instance.commonState();
  }));
  return mappedInstances;
}

/**
 * @param snapshotDistributorFactory Predeployed SnapshotDistributor factory instance
 * @param issuer Filter SnapshotDistributors by this issuer
 * @returns Array of SnapshotDistributor states
 */
export async function fetchSnapshotDistributorInstancesForIssuer(snapshotDistributorFactory: Contract, issuer: Contract): Promise<Object> {
  const instances = await snapshotDistributorFactory.getInstancesForIssuer(issuer.address);
  const mappedInstances = await Promise.all(instances.map(async (instanceAddress: string) => {
    const instance = await ethers.getContractAt("SnapshotDistributor", instanceAddress);
    return instance.commonState();
  }));
  return mappedInstances;
}

/**
 * @param snapshotDistributorFactory Predeployed SnapshotDistributor factory instance
 * @param asset Filter snapshot distributors by this asset
 * @returns Array of snapshot distributors states
 */
export async function fetchSnapshotDistributorInstancesForAsset(snapshotDistributorFactory: Contract, asset: Contract): Promise<object> {
  const instances = await snapshotDistributorFactory.getInstancesForAsset(asset.address);
  const mappedInstances = await Promise.all(instances.map(async (instanceAddress: string) => {
    const instance = await ethers.getContractAt("SnapshotDistributor", instanceAddress);
    return instance.commonState();
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
export async function fetchCampaignStateById(cfManagerFactory: Contract, id: Number): Promise<object> {
  const instanceAddress = await cfManagerFactory.instances(id);
  const instance = await ethers.getContractAt("CfManagerSoftcap", instanceAddress);
  return instance.getState();
}

/**
 * @param assetFactory Predeployed Asset factory instance
 * @param id Asset id
 * @returns Asset state
 */
export async function fetchAssetStateById(assetFactory: Contract, id: Number): Promise<object> {
  const instanceAddress = await assetFactory.instances(id);
  const instance = await ethers.getContractAt("Asset", instanceAddress);
  return instance.getState();
}

export async function fetchAssetTransferableStateById(assetFactory: Contract, id: Number): Promise<object> {
  const instanceAddress = await assetFactory.instances(id);
  const instance = await ethers.getContractAt("AssetTransferable", instanceAddress);
  return instance.getState();
}

/**
 * @param snapshotDistributor Predeployed SnapshotDistributor factory
 * @param id SnapshotDistributor id
 * @returns SnapshotDistributor state 
 */
export async function fetchSnapshotDistributorStateById(snapshotDistributorFactory: Contract, id: Number): Promise<object> {
  const instanceAddress = await snapshotDistributorFactory.instances(id);
  const instance = await ethers.getContractAt("SnapshotDistributor", instanceAddress);
  return instance.commonState();
}

/**
 * Fetches transaction history for given user wallet and issuer instance.
 * To calculate this, one must fetch all the instances of the following contracts for given issuer: 
 * -> Asset (for asset token transfers, if any)
 * -> CfManagerSoftcap (for investment, cancel investment and claim tokens transactions)
 * -> SnapshotDistributor (for revenue share claim transactions)
 * Then after all the contract instances have been fetched, we scan for specific events and filter
 * by the user's wallet.
 * 
 * @param wallet User wallet address
 * @param issuer Issuer contract instance
 * @param cfManagerFactory Predeployed CfManager contract factory
 * @param assetFactory Predeployed Asset contract factory
 * @param snapshotDistributorFactory Predeployed SnapshotDistributor contract factory
 */
export async function fetchTxHistory(
  wallet: string,
  issuer: Contract,
  cfManagerFactory: Contract,
  assetFactory: Contract,
  snapshotDistributorFactory: Contract
) {
  const assetTransactions = await filters.getAssetTransactions(wallet, issuer, assetFactory);;
  const crowdfundingTransactions = await filters.getCrowdfundingCampaignTransactions(wallet, issuer, cfManagerFactory);
  const snapshotDistributorTransactions = await filters.getSnapshotDistributorTransactions(wallet, issuer, snapshotDistributorFactory);
  const transactions = assetTransactions.concat(crowdfundingTransactions).concat(snapshotDistributorTransactions);
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

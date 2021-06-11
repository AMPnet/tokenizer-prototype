import { ethers } from "hardhat";
import * as helpers from "../util/helpers";

async function main() {
  const accounts = await ethers.getSigners();
  const deployer = accounts[0];
  const deployerAddress = await accounts[0].getAddress();
  const tokenizedAssetShareholderA = await accounts[1].getAddress();
  const tokenizedAssetShareholderB = await accounts[2].getAddress();

  const stablecoin = await helpers.deployStablecoin(deployer, "7000000");
  const registry = await helpers.deployGlobalRegistry(deployer);
  const issuer = await helpers.createIssuer(deployer, registry, stablecoin.address);

  await issuer.approveWallet(deployerAddress);
  await issuer.approveWallet(tokenizedAssetShareholderA);
  await issuer.approveWallet(tokenizedAssetShareholderB);

  const [cfManager, crowdfundingAsset] = await helpers.createCfManager(
    deployer,
    issuer,
    13,
    1000000,
    "Test Asset 1",
    "TA-1",
    10000,
    1000000,
    helpers.currentTimeWithDaysOffset(100),
  );
  await issuer.approveWallet(crowdfundingAsset.address);

  const tokenizedAsset = await helpers.createAsset(
    deployer,
    issuer,
    13,
    1000000,
    "Test Asset 2",
    "TA-2",
  );

  await tokenizedAsset.addShareholder(
    tokenizedAssetShareholderA,
    ethers.utils.parseEther(String("500000"))
  );
  await tokenizedAsset.addShareholder(
    tokenizedAssetShareholderB,
    ethers.utils.parseEther(String("500000"))
  );

  const payoutManager = await helpers.createPayoutManager(
    deployer,
    registry,
    tokenizedAsset.address
  );
  const revenuePayoutWei = ethers.utils.parseEther(String(10000));
  await stablecoin.approve(payoutManager.address, revenuePayoutWei);
  await payoutManager.createPayout("Q3/2020 Ape-le shareholders payout timeee", revenuePayoutWei);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });

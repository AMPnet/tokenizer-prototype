import { BigNumber, BigNumberish, Contract } from "ethers";
import { ethers } from "hardhat";

interface Transaction {
    timestamp: Date
}

export async function getAssetTransactions(wallet: string, issuer: Contract, assetFactory: Contract, assetType: string): Promise<Array<Transaction>> {
    const transactions = [];
    const assetInstanceAddresses = await assetFactory.getInstancesForIssuer(issuer.address);
    const assetInstancesPromisified: [Promise<Contract>] = assetInstanceAddresses.map(async (address: string) => {
      return ethers.getContractAt(assetType, address);
    });
    const assetInstances = await Promise.all(assetInstancesPromisified);
    const assetInstancesScanActions = assetInstances.map(async (asset: Contract) => {
      const filterFrom = await asset.queryFilter(asset.filters.Transfer(wallet, null))
      if (filterFrom) {
        for (const event of filterFrom) {
          const block = await event.getBlock();
          transactions.push({
            type: "TOKEN-TRANSFER", 
            from: event.args?.from,
            to: event.args?.to,
            amount: event.args?.value.toString(),
            asset: event.address,
            timestamp: toDateTime(block.timestamp)
          });
        }
      }
      const filterTo = await asset.queryFilter(asset.filters.Transfer(null, wallet));
      if (filterTo) {
        for (const event of filterTo) {
          const block = await event.getBlock();
          transactions.push({
            type: "TOKEN-TRANSFER",
            from: event.args?.from,
            to: event.args?.to,
            amount: event.args?.value.toString(),
            asset: event.address,
            timestamp: toDateTime(block.timestamp)
          })
        }
      }
    });
    await Promise.all(assetInstancesScanActions);
    return transactions;
}

export async function getCrowdfundingCampaignTransactions(wallet: string, issuer: Contract, cfManagerFactory: Contract, campaignType: string): Promise<Array<Transaction>> {
    const transactions = [];
    const cfManagerInstanceAddresses = await cfManagerFactory.getInstancesForIssuer(issuer.address);
    const cfManagerInstancesPromisifed: [Promise<Contract>] = cfManagerInstanceAddresses.map(async (address: string) => {
      return ethers.getContractAt(campaignType, address);
    });
    const cfManagerInstances = await Promise.all(cfManagerInstancesPromisifed);
    const cfManagerInstancesScanActions = cfManagerInstances.map(async (cfManager: Contract) => {
        const filterInvest = await cfManager.queryFilter(cfManager.filters.Invest(wallet));
        if (filterInvest) {
          for (const event of filterInvest) {
            transactions.push({
              type: "INVEST", 
              from: event.args?.investor,
              to: event.address,
              amount: event.args?.tokenValue.toString(),
              tokenAmount: event.args?.tokenAmount.toString(),
              timestamp: toDateTime(event.args?.timestamp)
            });
          }
        }
        const filterCancelInvest = await cfManager.queryFilter(cfManager.filters.CancelInvestment(wallet));
        if (filterCancelInvest) {
          for (const event of filterCancelInvest) {
            transactions.push({
              type: "CANCEL-INVESTMENT",
              from: event.address,
              to: event.args?.investor,
              amount: event.args?.tokenValue.toString(),
              tokenAmount: event.args?.tokenAmount.toString(),
              timestamp: toDateTime(event.args?.timestamp)
            });
          }
        }
        const filterClaimTokens = await cfManager.queryFilter(cfManager.filters.Claim(wallet));
        if (filterClaimTokens) {
          for (const event of filterClaimTokens) {
            transactions.push({
              type: "CLAIM-TOKENS",
              from: event.address,
              to: event.args?.investor,
              amount: event.args?.tokenValue?.toString(),
              tokenAmount: event.args?.tokenAmount?.toString(),
              timestamp: toDateTime(event.args?.timestamp)
            });
          }
        }
    });
    await Promise.all(cfManagerInstancesScanActions);
    return transactions;
}

export async function getSnapshotDistributorTransactions(wallet: string, issuer: Contract, snapshotDistributorFactory: Contract): Promise<Array<Transaction>> {
    const transactions = [];
    const snapshotDistributorInstanceAddresses = await snapshotDistributorFactory.getInstancesForIssuer(issuer.address);
    const snapshotDistributorInstancesPromisifed: [Promise<Contract>] = snapshotDistributorInstanceAddresses.map(async (address: string) => {
      return ethers.getContractAt("SnapshotDistributor", address);
    });
    const snapshotDistributorInstances = await Promise.all(snapshotDistributorInstancesPromisifed);
    const snapshotDistributorInstancesScanActions = snapshotDistributorInstances.map(async (snapshotDistributor: Contract) => {
        const filterRevenueShare = await snapshotDistributor.queryFilter(snapshotDistributor.filters.Release(wallet));
        if (filterRevenueShare) {
          for (const event of filterRevenueShare) {
            transactions.push({
              type: "REVENUE-SHARE",
              from: event.address,
              to: event.args?.investor,
              amount: event.args?.amount.toString(),
              asset: event.args?.asset,
              payoutId: event.args?.payoutId.toNumber(),
              timestamp: toDateTime(event.args?.timestamp)
            });
          }
        }
    });
    await Promise.all(snapshotDistributorInstancesScanActions);
    return transactions;
}

function toDateTime(unixTimestamp: BigNumberish): Date {
    const bn = BigNumber.from(unixTimestamp.toString())
    return new Date(bn.mul(1000).toNumber());
}

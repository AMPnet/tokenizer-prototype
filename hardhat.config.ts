import { task } from "hardhat/config";
import "@nomiclabs/hardhat-waffle";
import * as dotenv from 'dotenv';
dotenv.config();

// This is a sample Hardhat task. To learn how to create your own go to
// https://hardhat.org/guides/create-task.html
task("accounts", "Prints the list of accounts", async (args, hre) => {
  const accounts = await hre.ethers.getSigners();

  for (const account of accounts) {
    console.log(await account.address);
  }
});

// You need to export an object to set up your config
// Go to https://hardhat.org/config/ to learn more

/**
 * @type import('hardhat/config').HardhatUserConfig
 */
module.exports = {
  solidity: "0.8.0",
  networks: {
    ropsten: {
      url: process.env.ROPSTEN_RPC,
      accounts: {
        mnemonic: process.env.SEED_PHRASE
      }
    },
    goerli: {
      url: "https://goerli.infura.io/v3/08664baf7af14eda956db2b71a79f12f",
      accounts: {
        mnemonic: "pride mercy describe result ripple wasp meat organ invest feature avoid boy"
      }
    },
    mumbai: {
      url: process.env.MUMBAI_RPC,
      accounts: {
        mnemonic: process.env.SEED_PHRASE
      }
    }
  }
};

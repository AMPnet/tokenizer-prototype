import { task } from "hardhat/config";
import '@nomiclabs/hardhat-ethers';
import "@nomiclabs/hardhat-waffle";
import "@nomiclabs/hardhat-solhint";
import '@typechain/hardhat';
import "hardhat-gas-reporter";
import "hardhat-contract-sizer";
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
type NetworkConfig = {
  [key: string]: {
    url: string,
    accounts: {
      mnemonic: string
    },
    gasPrice?: number
  }
}
function networks() {
 let networks: NetworkConfig = {}
 if (process.env.SEED_PHRASE) {
   if (process.env.ROPSTEN_RPC) {
     networks["ropsten"] = {
        url: process.env.ROPSTEN_RPC,
        accounts: {
          mnemonic: process.env.SEED_PHRASE
        }
     }
   }
   if (process.env.GOERLI_RPC) {
    networks["goerli"] = {
       url: process.env.GOERLI_RPC,
       accounts: {
         mnemonic: process.env.SEED_PHRASE
       },
       gasPrice: 30000000000
    }
   }
   if (process.env.MUMBAI_RPC) {
    networks["mumbai"] = {
       url: process.env.MUMBAI_RPC,
       accounts: {
         mnemonic: process.env.SEED_PHRASE
       },
       gasPrice: 10000000000
    }
  }
  if (process.env.MATIC_RPC) {
    networks["matic"] = {
       url: process.env.MATIC_RPC,
       accounts: {
         mnemonic: process.env.SEED_PHRASE
       },
       gasPrice: 30000000000
    }
  }
  if (process.env.AURORA_TESTNET_RPC) {
    networks["aurora-testnet"] = {
       url: process.env.AURORA_TESTNET_RPC,
       accounts: {
         mnemonic: process.env.SEED_PHRASE
       },
       gasPrice: 10000000000
    }
  }
  if (process.env.PRIVATE_RPC) {
    networks["private"] = {
       url: process.env.PRIVATE_RPC,
       accounts: {
         mnemonic: process.env.SEED_PHRASE
       },
       gasPrice: 0
    }
  }
 }
 return networks;
}

module.exports = {
  solidity: {
    version: "0.8.0",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200
      }
    }
  },
  networks: networks(),
  typechain: {
    target: 'ethers-v5',
    alwaysGenerateOverloads: false
  }
};

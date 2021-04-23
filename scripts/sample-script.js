// We require the Hardhat Runtime Environment explicitly here. This is optional 
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
const hre = require("hardhat");

async function main() {
  // Hardhat always runs the compile task when running scripts with its command
  // line interface.
  //
  // If this script is run directly using `node` you may want to call compile 
  // manually to make sure everything is compiled
  // await hre.run('compile');

  // We get the contract to deploy
  const Synthetic = await hre.ethers.getContractFactory("Synthetic");
  const synthetic = await Synthetic.deploy(
    '0x59cca525aa95d154cc4425877665b246c0e5945d',   // Issuer address
    0,                                              // Category ID
    0,                                              // State: CREATION
    100,                                            // Shares supply
    'Test Synthetic',                               // Synthetic name
    'TSN'                                           // Synthetic symbol
  );

  await synthetic.deployed();

  console.log("Synthetic deployed to:", synthetic.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });

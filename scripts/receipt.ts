import { ethers } from "hardhat";
import * as getRevertReason from "eth-revert-reason";

async function main() {
    const account1 = ethers.provider.getSigner(1);
    console.log("acc1", await account1.getAddress());
}

main()
.then(() => process.exit(0))
.catch((error) => {
  console.error(error);
  process.exit(1);
});
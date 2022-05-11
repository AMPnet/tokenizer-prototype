// @ts-ignore
import { ethers } from "hardhat";

export async function advanceBlockTime(time: Number): Promise<String> {
    const response = await ethers.provider.send("evm_mine", [time]);
    console.log("response", response);
    const latest = await ethers.provider.getBlock("latest");
    return latest.hash;
}

export function log(message: string, opts?: { logOutput: boolean }) {
    if (!opts || opts?.logOutput === true) {
        console.log(message);
    }
}

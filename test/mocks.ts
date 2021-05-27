import { ethers } from "hardhat";
import { ContractFactory } from "ethers";
import { smockit, smoddit } from "@eth-optimism/smock";

const ADDRESS_ZERO = ethers.constants.AddressZero;

export async function createIssuerNoWhitelisting() {
    const Issuer: ContractFactory = await ethers.getContractFactory("Issuer");
    const issuer = await Issuer.deploy(ADDRESS_ZERO, ADDRESS_ZERO, ADDRESS_ZERO);
    const issuerMock = await smockit(issuer);
    issuerMock.smocked.isWalletApproved.will.return.with(true);
    return issuerMock;
}

export async function createIssuerModifiable() {
    const IssuerModifiable = await smoddit("Issuer");
    const issuerModifiable = await IssuerModifiable.deploy(ADDRESS_ZERO, ADDRESS_ZERO, ADDRESS_ZERO);
    return issuerModifiable;
}
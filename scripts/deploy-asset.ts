import { ethers } from "hardhat";

async function main() {
    const PROCEDURE_IPFS = "QmUutXQm7FWVWjHiSFENprk7j7KDwW3NCqkAtDJdgEazj9";
    const ADDRESS_ZERO = ethers.constants.AddressZero;
    
    const ASSET_CATEGORY_ID = 42;
    const ASSET_TOKENIZED_STATE = 1;
    const ASSET_TOTAL_SHARES = ethers.utils.parseEther("100");
    const ASSET_IPFS = "QmdxwTrkQAmXSs7FEbMXJWrBqYQfZ6j9o5BzYrNLLuw4xg";

    const accounts = await ethers.getSigners();
    const deployerAddress = await accounts[0].getAddress();

    const GlobalRegistry = await ethers.getContractFactory("GlobalRegistry");
    const globalRegistry = await GlobalRegistry.deploy(ADDRESS_ZERO, ADDRESS_ZERO, ADDRESS_ZERO, ADDRESS_ZERO);
    console.log("globalRegistry", globalRegistry.address);

    const setAuditingProcedureResult = await globalRegistry.setAuditingProcedure(ASSET_CATEGORY_ID, PROCEDURE_IPFS);
    console.log("setAuditingProcedureResult", setAuditingProcedureResult);

    const Asset = await ethers.getContractFactory("Asset");
    const asset = await Asset.deploy(
        deployerAddress,
        ADDRESS_ZERO,
        ASSET_TOKENIZED_STATE,
        ASSET_CATEGORY_ID,
        ASSET_TOTAL_SHARES,
        "APX(CRESE12)",
        "AAPX Swedish Commercial Real-Estate-Synthetic #12"
    );
    console.log("asset", asset.address);

    const setAssetInfoResult = await asset.setInfo(ASSET_IPFS);
    console.log("setAssetInfoResult", setAssetInfoResult);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });

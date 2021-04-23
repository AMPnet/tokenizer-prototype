const { expect } = require("chai");

describe("Synthetic", function() {
  it("Should deploy and call synthetic functions successfully", async function() {
    const Synthetic = await ethers.getContractFactory("Synthetic");
    const synthetic = await Synthetic.deploy(
      '0x59cca525aa95d154cc4425877665b246c0e5945d',   // Issuer address
      0,                                              // Category ID
      0,                                              // State: CREATION
      100,                                            // Shares supply
      'Test Synthetic',                               // Synthetic name
      'TSN'                                           // Synthetic symbol
    );
    
    await synthetic.deployed();
    expect(await synthetic.totalSupply()).to.equal(100);
  });
});

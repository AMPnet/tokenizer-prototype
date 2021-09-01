// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IMirroredToken {

    // Write

    function mintMirrored(address wallet, uint256 amount) external;
    function burnMirrored(uint256 amount) external;
    function updateTokenPrice(uint256 price, uint256 expiry) external;
    function liquidate() external returns (uint256);
    function claimLiquidationShare(address investor) external;
    
    // Read

    function lastKnownMarketCap() external view returns(uint256);

}

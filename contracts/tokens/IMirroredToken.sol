// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IMirroredToken {

    // Write

    function convertFromOriginal() external;
    function updateTokenPrice(uint256 price, uint256 expiry) external;
    function liquidate() external;
    function claimLiquidationShare(address investor) external;
    
    // Read

    function lastKnownTokenValue() external view returns(uint256);
    function circulatingSupply() external view returns(uint256);

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ICfManagerSoftcapFactory {
    function create(
        address owner,
        string memory ansName,
        address assetAddress,
        uint256 initialPricePerToken,
        uint256 softCap,
        uint256 minInvestment,
        uint256 maxInvestment,
        bool whitelistRequired,
        string memory info
    ) external returns (address);
    function getInstances() external view returns (address[] memory);
    function getInstancesForAsset(address asset) external view returns (address[] memory);
    function getInstancesForIssuer(address issuer) external view returns (address[] memory);
    function namespace(address issuer, string memory ansName) external view returns (address);
}

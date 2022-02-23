// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../shared/IVersioned.sol";

interface INameRegistry is IVersioned {
    
    // WRITE
    function transferOwnership(address newOwner) external;
    function setFactories(address[] memory factories, bool[] memory active) external;
    function mapIssuer(string memory name, address instance) external;
    function mapAsset(string memory name, address instance) external;
    function mapCampaign(string memory name, address instance) external;

    // READ
    function getIssuer(string memory name) external view returns (address);
    function getIssuerName(address issuer) external view returns (string memory);
    function getAsset(string memory name) external view returns (address);
    function getAssetName(address asset) external view returns (string memory);
    function getCampaign(string memory name) external view returns (address);
    function getCampaignName(address campaign) external view returns (string memory);

}

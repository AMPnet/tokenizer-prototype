// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface INameRegistry {
    
    // WRITE
    function transferOwnership(address newOwner) external;
    function setFactories(address[] memory factories, bool[] memory active) external;
    function mapIssuer(string memory name, address instance) external;
    function mapAsset(string memory name, address instance) external;
    function mapCampaign(string memory name, address instance) external;


    // READ
    function getIssuer(string memory name) external view returns (address);
    function getAsset(string memory name) external view returns (address);
    function getCampaign(string memory name) external view returns (address);

}

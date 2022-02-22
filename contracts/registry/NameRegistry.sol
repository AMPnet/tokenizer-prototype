// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./INameRegistry.sol";

contract NameRegistry is INameRegistry {

    string constant public FLAVOR = "NameRegistryV1";
    string constant public VERSION = "1.0.30";

    //------------------------
    //  STATE
    //------------------------
    address public owner;
    mapping (address => bool) private whitelistedFactories;
    mapping (string => address) private issuerNameToAddressMap;
    mapping (address => string) private issuerAddressToNameMap;
    mapping (string => address) private assetNameToAddressMap;
    mapping (address => string) private assetAddressToNameMap;
    mapping (string => address) private campaignNameToAddressMap;
    mapping (address => string) private campaignAddressToNameMap;

    //------------------------
    //  EVENTS
    //------------------------
    event SetFactory(address factory, bool status, uint256 timestamp);
    event TransferOwnership(address oldOwner, address newOwner, uint256 timestamp);
    event MapIssuer(address indexed caller, string name, address instance, uint256 timestamp);
    event MapAsset(address indexed caller, string name, address instance, uint256 timestamp);
    event MapCampaign(address indexed caller, string name, address instance, uint256 timestamp);

    //------------------------
    //  CONSTRUCTOR
    //------------------------
    constructor(address _owner, address[] memory _whitelistedFactories, bool[] memory _isWhitelisted) {
        owner = _owner;
        _setFactories(_whitelistedFactories, _isWhitelisted);
    }

    //------------------------
    //  MODIFIERS
    //------------------------
    modifier ownerOnly() {
        require(msg.sender == owner, "NameRegistry: only owner can call this function");
        _;
    }

    modifier whitelistedFactoryOnly() {
        require(whitelistedFactories[msg.sender], "NameRegistry: only whitelisted factory can call this function");
        _;
    }

    //-----------------------------
    //  INameRegistry IMPL - WRITE
    //-----------------------------
    function transferOwnership(address newOwner) external override ownerOnly {
        address oldOwner = owner;
        owner = newOwner;
        emit TransferOwnership(oldOwner, newOwner, block.timestamp);
    }

    function setFactories(address[] memory factories, bool[] memory active) external override ownerOnly {
        _setFactories(factories, active);
    }

    function mapIssuer(string memory name, address instance) external override whitelistedFactoryOnly {
        issuerNameToAddressMap[name] = instance;
        issuerAddressToNameMap[instance] = name;
        emit MapIssuer(msg.sender, name, instance, block.timestamp);
    }

    function mapAsset(string memory name, address instance) external override whitelistedFactoryOnly {
        assetNameToAddressMap[name] = instance;
        assetAddressToNameMap[instance] = name;
        emit MapAsset(msg.sender, name, instance, block.timestamp);
    }

    function mapCampaign(string memory name, address instance) external override whitelistedFactoryOnly {
        campaignNameToAddressMap[name] = instance;
        campaignAddressToNameMap[instance] = name;
        emit MapCampaign(msg.sender, name, instance, block.timestamp);
    }

    //-----------------------------
    //  INameRegistry IMPL - READ
    //-----------------------------
    function flavor() external pure override returns (string memory) { return FLAVOR; }
    
    function version() external pure override returns (string memory) { return VERSION; }
    
    function getIssuer(string memory name) external override view returns (address) {
        return issuerNameToAddressMap[name];
    }

    function getIssuerName(address issuer) external view override returns (string memory) {
        return issuerAddressToNameMap[issuer];
    }

    function getAsset(string memory name) external override view returns (address) {
        return assetNameToAddressMap[name];
    }

    function getAssetName(address asset) external view override returns (string memory) {
        return assetAddressToNameMap[asset];
    }

    function getCampaign(string memory name) external override view returns (address) {
        return campaignNameToAddressMap[name];
    }

    function getCampaignName(address campaign) external view override returns (string memory) {
        return campaignAddressToNameMap[campaign];
    }

    //------------------------
    //  Helpers
    //------------------------
    function _setFactories(address[] memory factories, bool[] memory isWhitelisted) private {
        require(
            factories.length == isWhitelisted.length,
            "NameRegistry: factoryAddress and fectoryStatus array size mismatch"
        );
        for (uint256 i = 0; i < factories.length; i++) {
            address factory = factories[i];
            bool status = isWhitelisted[i];
            whitelistedFactories[factory] = status;
            emit SetFactory(factory, status, block.timestamp);
        }
    }

}

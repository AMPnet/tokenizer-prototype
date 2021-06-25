// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { IIssuer } from "../issuer/IIssuer.sol";
import { ICfManager } from "../managers/crowdfunding/ICfManager.sol";
import { IAssetFactory } from "../asset/IAssetFactory.sol";
import { ICfManagerFactory } from "../managers/crowdfunding/ICfManagerFactory.sol";
import { AssetState } from "../shared/Enums.sol";
import { IGlobalRegistry } from "../shared/IGlobalRegistry.sol";

contract Issuer is IIssuer {

    address public owner;
    address public override stablecoin;
    IGlobalRegistry public registry;
    mapping (address => bool) public approvedWallets;
    address[] public assets;
    address[] public cfManagers;
    string public override info;

    constructor(address _owner, address _stablecoin, address _registry, string memory _info) {
        owner = _owner;
        stablecoin = _stablecoin;
        registry = IGlobalRegistry(_registry);
        info = _info;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    modifier walletApproved(address _wallet) {
        require(
            approvedWallets[_wallet],
            "This action is forbidden. Wallet not approved by the Issuer."
        );
        _;
    }

    function approveWallet(address _wallet) external onlyOwner {
        approvedWallets[_wallet] = true;
    }

    function suspendWallet(address _wallet) external onlyOwner {
        approvedWallets[_wallet] = false;
    }

    function setInfo(string memory _info) external onlyOwner {
        info = _info;
    }

    function createAsset(
        uint256 _categoryId,
        uint256 _totalShares,
        AssetState _state,
        string memory _name,
        string memory _symbol
    ) external walletApproved(msg.sender) returns (address)
    {
        address asset = IAssetFactory(registry.assetFactory()).create(
            msg.sender,
            address(this),
            _state,
            _categoryId,
            _totalShares,
            _name,
            _symbol
        );
        assets.push(asset);
        return asset;
    }

    function createCrowdfundingCampaign(
        uint256 _categoryId,
        uint256 _totalShares,
        string memory _name,
        string memory _symbol,
        uint256 _minInvestment,
        uint256 _maxInvestment,
        uint256 _endsAt
    ) external onlyOwner returns(address)
    {
        address manager;
        address asset;
        manager = ICfManagerFactory(registry.cfManagerFactory()).create(
            msg.sender,
            _minInvestment,
            _maxInvestment,
            _endsAt  
        );
        asset = IAssetFactory(registry.assetFactory()).create(
            manager,
            address(this),
            AssetState.CREATION,
            _categoryId,
            _totalShares,
            _name,
            _symbol
        );
        ICfManager(manager).setAsset(asset);
        assets.push(asset);
        cfManagers.push(manager);
        return manager;
    }

    function isWalletApproved(address _wallet) external view override returns (bool) {
        return approvedWallets[_wallet];
    }

    function getAssets() external override view returns (address[] memory) { return assets; }

    function getCfManagers() external override view returns (address[] memory) { return cfManagers; }

}

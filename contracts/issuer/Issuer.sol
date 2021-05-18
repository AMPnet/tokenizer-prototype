// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { IIssuer } from "../issuer/IIssuer.sol";
import { ICfManager } from "../managers/crowdfunding/ICfManager.sol";
import { IAssetFactory } from "../asset/IAssetFactory.sol";
import { ICfManagerFactory } from "../managers/crowdfunding/ICfManagerFactory.sol";
import { AssetState } from "../shared/Enums.sol";

contract Issuer is IIssuer {

    address public owner;
    address public override stablecoin;
    IAssetFactory public assetFactory;
    ICfManagerFactory public cfManagerFactory;
    mapping (address => bool) public approvedWallets;
    address[] public assets;
    address[] public cfManagers;

    constructor(address _owner, address _stablecoin, address _assetFactory, address _cfManagerFactory) {
        owner = _owner;
        stablecoin = _stablecoin;
        assetFactory = IAssetFactory(_assetFactory);
        cfManagerFactory = ICfManagerFactory(_cfManagerFactory);
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

    function createAsset(
        uint256 _categoryId,
        uint256 _totalShares,
        AssetState _state,
        string memory _name,
        string memory _symbol
    ) external walletApproved(msg.sender) returns (address)
    {
        address asset = assetFactory.create(
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
    ) external walletApproved(msg.sender) returns(address)
    {
        address manager;
        address asset;
        manager = cfManagerFactory.create(
            msg.sender,
            _minInvestment,
            _maxInvestment,
            _endsAt  
        );
        asset = assetFactory.create(
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

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { IIssuer } from "../issuer/IIssuer.sol";
import { ICfManager } from "../managers/crowdfunding/ICfManager.sol";
import { IAssetFactory } from "../asset/IAssetFactory.sol";
import { ICfManagerFactory } from "../managers/crowdfunding/ICfManagerFactory.sol";
import { IGlobalRegistry } from "../shared/IGlobalRegistry.sol";
import { IssuerState, InfoEntry } from "../shared/Structs.sol";
import { AssetFundingState } from "../shared/Enums.sol";

contract Issuer is IIssuer {

    //------------------------
    //  STATE
    //------------------------
    IssuerState private state;
    InfoEntry[] private infoHistory;
    mapping (address => bool) public approvedWallets;
    address[] public assets;
    address[] public cfManagers;

    //------------------------
    //  EVENTS
    //------------------------
    event WalletApprove(address approver, address wallet, uint256 timestamp);
    event WalletSuspend(address approver, address wallet, uint256 timestamp);
    event ChangeWalletApprover(address oldWalletApprover, address newWalletApprover, uint256 timestamp);
    event SetInfo(string info, address setter);

    //------------------------
    //  CONSTRUCTOR
    //------------------------
    constructor(
        uint256 id,
        address owner,
        address stablecoin,
        address registry,
        address walletApprover,
        string memory info
    ) {
        infoHistory.push(InfoEntry(
            info,
            block.timestamp
        ));
        state = IssuerState(
            id,
            owner,
            stablecoin,
            IGlobalRegistry(registry),
            walletApprover,
            info
        );
    }

    //------------------------
    //  MODIFIERS
    //------------------------
    modifier onlyOwner {
        require(msg.sender == state.owner);
        _;
    }

    modifier onlyWalletApprover {
        require(msg.sender == state.walletApprover);
        _;
    }

    modifier walletApproved(address wallet) {
        require(
            approvedWallets[wallet],
            "This action is forbidden. Wallet not approved by the Issuer."
        );
        _;
    }

    //------------------------
    //  STATE CHANGE FUNCTIONS
    //------------------------
    function approveWallet(address wallet) external onlyWalletApprover {
        approvedWallets[wallet] = true;
        emit WalletApprove(msg.sender, wallet, block.timestamp);
    }

    function suspendWallet(address wallet) external onlyWalletApprover {
        approvedWallets[wallet] = false;
        emit WalletSuspend(msg.sender, wallet, block.timestamp);
    }

    function setInfo(string memory info) external onlyOwner {
        infoHistory.push(InfoEntry(
            info,
            block.timestamp
        ));
        state.info = info;
        emit SetInfo(info, msg.sender);
    }

    function changeWalletApprover(address newWalletApprover) external onlyOwner {
        state.walletApprover = newWalletApprover;
        emit ChangeWalletApprover(state.walletApprover, newWalletApprover, block.timestamp);
    }

    function createAsset(
        uint256 initialTokenSupply,
        uint256 initialPricePerToken,
        AssetFundingState fundingState,
        string memory name,
        string memory symbol,
        string memory info
    ) external onlyOwner returns (address)
    {
        address asset = IAssetFactory(state.registry.assetFactory()).create(
            msg.sender,
            address(this),
            fundingState,
            initialTokenSupply,
            initialPricePerToken,
            name,
            symbol,
            info
        );
        assets.push(asset);
        return asset;
    }

    function createCrowdfundingCampaign(
        uint256 initialTokenSupply,
        uint256 initialPricePerToken,
        string memory name,
        string memory symbol,
        uint256 minInvestment,
        uint256 maxInvestment,
        uint256 endsAt,
        string memory campaignInfo,
        string memory assetInfo
    ) external onlyOwner returns(address)
    {
        address manager;
        address asset;
        {
            manager = ICfManagerFactory(state.registry.cfManagerFactory()).create(
                msg.sender,
                initialPricePerToken,
                minInvestment,
                maxInvestment,
                endsAt,
                campaignInfo
            );
        }
        {
            asset = IAssetFactory(state.registry.assetFactory()).create(
                manager,
                address(this),
                AssetFundingState.CREATION,
                initialTokenSupply,
                initialPricePerToken,
                name,
                symbol,
                assetInfo
            );
        }
        ICfManager(manager).setAsset(asset);
        assets.push(asset);
        cfManagers.push(manager);
        return manager;
    }

    //------------------------
    //  IIssuer IMPL
    //------------------------
    function getState() external override view returns (IssuerState memory) { return state; }

    function getAssets() external override view returns (address[] memory) { return assets; }

    function getCfManagers() external override view returns (address[] memory) { return cfManagers; }
    
    function isWalletApproved(address wallet) external view override returns (bool) {
        return approvedWallets[wallet];
    }

    function getInfoHistory() external view override returns (InfoEntry[] memory) {
        return infoHistory;
    }

}

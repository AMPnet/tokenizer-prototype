// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { IIssuer } from "./interfaces/IIssuer.sol";
import { ICfManager } from "./interfaces/ICfManager.sol";
import { ISyntheticFactory } from "./interfaces/ISyntheticFactory.sol";
import { ICfManagerFactory } from "./interfaces/ICfManagerFactory.sol";
import { SyntheticState } from "./Enums.sol";

contract Issuer is IIssuer, Ownable {

    address public override stablecoin;
    ISyntheticFactory public syntheticFactory;
    ICfManagerFactory public cfManagerFactory;
    mapping (address => bool) public approvedWallets;
    address[] public synthetics;
    address[] public cfManagers;

    constructor(address _stablecoin, address _syntheticFactory, address _cfManagerFactory) {
        stablecoin = _stablecoin;
        syntheticFactory = ISyntheticFactory(_syntheticFactory);
        cfManagerFactory = ICfManagerFactory(_cfManagerFactory);
    }

    event CfManagerCreated(address _cfManager);
    event SyntheticCreated(address _synthetic);

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

    function createSynthetic(
        uint256 _categoryId,
        uint256 _totalShares,
        SyntheticState _state,
        string memory _name,
        string memory _symbol
    ) external walletApproved(msg.sender) returns (address)
    {
        address synthetic = syntheticFactory.create(
            msg.sender,
            address(this),
            _state,
            _categoryId,
            _totalShares,
            _name,
            _symbol
        );
        synthetics.push(synthetic);
        emit SyntheticCreated(synthetic);
        return synthetic;
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
        address manager = cfManagerFactory.create(
            _minInvestment,
            _maxInvestment,
            _endsAt  
        );
        address synthetic = syntheticFactory.create(
            manager,
            address(this),
            SyntheticState.CREATION,
            _categoryId,
            _totalShares,
            _name,
            _symbol
        );
        ICfManager(manager).setSynthetic(synthetic);
        synthetics.push(synthetic);
        cfManagers.push(manager);
        emit CfManagerCreated(manager);
        emit SyntheticCreated(synthetic);
        return manager;
    }

    function isWalletApproved(address _wallet) external view override returns (bool) {
        return approvedWallets[_wallet];
    }

}

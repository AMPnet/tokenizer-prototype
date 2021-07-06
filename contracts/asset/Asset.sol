// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { ERC20Snapshot } from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Snapshot.sol";
import { IAsset } from "../asset/IAsset.sol";
import { IIssuer } from "../issuer/IIssuer.sol";
import { AssetFundingState } from "../shared/Enums.sol";
import { AssetState, InfoEntry } from "../shared/Structs.sol";

contract Asset is IAsset, ERC20Snapshot {

    //------------------------
    //  STATE
    //------------------------
    InfoEntry[] private infoHistory;
    AssetState private state;

    //------------------------
    //  EVENTS
    //------------------------
    event TransferToShareholder(address indexed shareholder, uint256 amount, uint256 timestamp);
    event RemoveFromShareholder(address indexed shareholder, uint256 amount, uint256 timestamp);
    event Finalize(address caller, address creator);
    event SetCreator(address indexed oldCreator, address indexed newCreator, uint256 timestamp);
    event SetInfo(string info, address setter);

    //------------------------
    //  CONSTRUCTOR
    //------------------------
    constructor(
        uint256 id,
        address creator,
        address issuer,
        AssetFundingState fundingState,
        uint256 initialTokenSupply,
        uint256 initialPricePerToken,
        string memory name,
        string memory symbol,
        string memory info
    ) ERC20(name, symbol)
    {
        infoHistory.push(InfoEntry(
            info,
            block.timestamp
        ));
        state = AssetState(
            id,
            creator,
            initialTokenSupply,
            initialPricePerToken,
            IIssuer(issuer),
            fundingState,
            info,
            name,
            symbol
        );
        _mint(creator, initialTokenSupply);
    }

    //------------------------
    //  MODIFIERS
    //------------------------
    modifier atFundingState(AssetFundingState fundingState) {
        require(
            state.fundingState == fundingState,
            "This functionality is not allowed while in the current Asset funding state."
        );
        _;
    }

    modifier walletApproved(address wallet) {
        require(
            state.issuer.isWalletApproved(wallet),
            "This functionality is not allowed. Wallet is not approved by the Issuer."
        );
        _;
    }

    modifier creatorOnly() {
        require(
            msg.sender == state.creator,
            "Only asset creator can make this action."
        );
        _;
    }

    //------------------------
    //  IAsset IMPL
    //------------------------
    function addShareholder(address shareholder, uint256 amount)
        external 
        override
        creatorOnly
        atFundingState(AssetFundingState.CREATION)
    {
        _transfer(state.creator, shareholder, amount);
        emit TransferToShareholder(shareholder, amount, block.timestamp);
    }

    function removeShareholder(address shareholder, uint256 amount)
        external
        override
        creatorOnly
        atFundingState(AssetFundingState.CREATION)
    {
        _transfer(shareholder, state.creator, amount);
        emit RemoveFromShareholder(shareholder, amount, block.timestamp);
    }

    function finalize(address owner)
        external
        override
        creatorOnly
        atFundingState(AssetFundingState.CREATION)
    {
        state.fundingState = AssetFundingState.TOKENIZED;
        state.creator = owner;
        emit Finalize(msg.sender, owner);
    }

    function setCreator(address creator)
        external
        override
        creatorOnly
        atFundingState(AssetFundingState.TOKENIZED)
    {
        state.creator = creator;
        emit SetCreator(msg.sender, creator, block.timestamp);
    }

    function setInfo(string memory info) external creatorOnly {
        infoHistory.push(InfoEntry(
            info,
            block.timestamp
        ));
        state.info = info;
        emit SetInfo(info, msg.sender);
    }

    function totalShares() external view override returns (uint256) {
        return totalSupply();
    }

    function getState() external view override returns (AssetState memory) {
        return state;
    }

    function getInfoHistory() external view override returns (InfoEntry[] memory) {
        return infoHistory;
    }

    //------------------------
    //  ERC20 OVERRIDES
    //------------------------
    function transfer(address recipient, uint256 amount)
        public
        override
        atFundingState(AssetFundingState.TOKENIZED)
        walletApproved(_msgSender())
        walletApproved(recipient)
        returns (bool)
    {
        return super.transfer(recipient, amount);
    }

    function approve(address spender, uint256 amount)
        public
        override
        atFundingState(AssetFundingState.TOKENIZED)
        walletApproved(_msgSender())
        walletApproved(spender)
        returns (bool)
    {
        return super.approve(spender, amount);
    }

    function transferFrom(address sender, address recipient, uint256 amount)
        public
        override
        atFundingState(AssetFundingState.TOKENIZED)
        walletApproved(sender)
        walletApproved(recipient)
        returns (bool)
    {
        return super.transferFrom(sender, recipient, amount);
    }

    function increaseAllowance(address spender, uint256 addedValue)
        public
        override
        atFundingState(AssetFundingState.TOKENIZED)
        walletApproved(_msgSender())
        walletApproved(spender)
        returns (bool)
    {
        return super.increaseAllowance(spender, addedValue);
    }

    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        override
        atFundingState(AssetFundingState.TOKENIZED)
        walletApproved(_msgSender())
        walletApproved(spender)
        returns (bool)
    {
        return super.decreaseAllowance(spender, subtractedValue);
    }

    //------------------------
    //  ERC20Snapshot
    //------------------------
    function snapshot() external override returns (uint256) {
        return _snapshot();
    }

}

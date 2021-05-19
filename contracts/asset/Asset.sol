// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { ERC20Snapshot } from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Snapshot.sol";
import { IAsset } from "../asset/IAsset.sol";
import { IIssuer } from "../issuer/IIssuer.sol";
import { AssetState } from "../shared/Enums.sol";

contract Asset is IAsset, ERC20Snapshot {

    //------------------------
    //  STATE
    //------------------------
    address public override creator;
    IIssuer public override issuer;
    uint256 public categoryId;
    AssetState public override state;
    string public override info;

    //------------------------
    //  MODIFIERS
    //------------------------
    modifier atState(AssetState _state) {
        require(
            state == _state,
            "This functionality is not allowed while in the current Asset state."
        );
        _;
    }

    modifier walletApproved(address _wallet) {
        require(
            issuer.isWalletApproved(_wallet),
            "This functionality is not allowed. Wallet is not approved by the Issuer."
        );
        _;
    }

    modifier creatorOnly() {
        require(
            msg.sender == creator,
            "Only asset creator can make this action."
        );
        _;
    }

    //------------------------
    //  CONSTRUCTOR
    //------------------------
    constructor(
        address _creator,
        address _issuer,
        AssetState _state,
        uint256 _categoryId,
        uint256 _totalShares,
        string memory _name,
        string memory _symbol
    ) ERC20(_name, _symbol)
    {
        creator = _creator;
        issuer = IIssuer(_issuer);
        categoryId = _categoryId;
        state = _state;
        _mint(_creator, _totalShares);
    }

    //------------------------
    //  EDIT STATE FUNCTIONS
    //------------------------
    function addShareholder(address shareholder, uint256 amount)
        external 
        override
        creatorOnly
        atState(AssetState.CREATION)
    {
        _transfer(creator, shareholder, amount);
    }

    function removeShareholder(address shareholder, uint256 amount)
        external
        override
        creatorOnly
        atState(AssetState.CREATION)
    {
        _transfer(shareholder, creator, amount);
    }

    function finalize()
        external
        override
        creatorOnly
        atState(AssetState.CREATION)
    {
        state = AssetState.TOKENIZED;
    }

    function setCreator(address _creator)
        external
        override
        creatorOnly
        atState(AssetState.TOKENIZED)
    {
        creator = _creator;
    }

    function setInfo(string memory _info) external creatorOnly {
        info = _info;
    }

    //------------------------
    //  IAsset IMPL
    //------------------------
    function totalShares() external view override returns (uint256) {
        return totalSupply();
    }

    //------------------------
    //  ERC20 OVERRIDES
    //------------------------
    function transfer(address recipient, uint256 amount)
        public
        override
        atState(AssetState.TOKENIZED)
        walletApproved(_msgSender())
        walletApproved(recipient)
        walletApproved(address(this))
        returns (bool)
    {
        return super.transfer(recipient, amount);
    }

    function approve(address spender, uint256 amount)
        public
        override
        atState(AssetState.TOKENIZED)
        walletApproved(_msgSender())
        walletApproved(spender)
        walletApproved(address(this))
        returns (bool)
    {
        return super.approve(spender, amount);
    }

    function transferFrom(address sender, address recipient, uint256 amount)
        public
        override
        atState(AssetState.TOKENIZED)
        walletApproved(sender)
        walletApproved(recipient)
        walletApproved(address(this))
        returns (bool)
    {
        return super.transferFrom(sender, recipient, amount);
    }

    function increaseAllowance(address spender, uint256 addedValue)
        public
        override
        atState(AssetState.TOKENIZED)
        walletApproved(_msgSender())
        walletApproved(spender)
        walletApproved(address(this))
        returns (bool)
    {
        return super.increaseAllowance(spender, addedValue);
    }

    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        override
        atState(AssetState.TOKENIZED)
        walletApproved(_msgSender())
        walletApproved(spender)
        walletApproved(address(this))
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

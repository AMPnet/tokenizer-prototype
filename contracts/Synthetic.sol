// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { ISynthetic } from "./interfaces/ISynthetic.sol";
import { IIssuer } from "./interfaces/IIssuer.sol";

contract Synthetic is ISynthetic, ERC20 {

    enum SyntheticState { CREATION, TOKENIZED }

    //------------------------
    //  STATE
    //------------------------
    address public override creator;
    IIssuer public override issuer;
    uint256 public categoryId;
    SyntheticState public state;

    //------------------------
    //  MODIFIERS
    //------------------------
    modifier atState(SyntheticState _state) {
        require(
            state == _state,
            "This functionality is not allowed while in the current Synthetic state."
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

    //------------------------
    //  CONSTRUCTOR
    //------------------------
    constructor(
        address _creator,
        IIssuer _issuer,
        SyntheticState _state,
        uint256 _categoryId,
        uint256 _totalShares,
        string memory _name,
        string memory _symbol
    ) ERC20(_name, _symbol)
    {
        creator = _creator;
        issuer = _issuer;
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
        atState(SyntheticState.CREATION)
        returns (bool) {
        require(
            _msgSender() == creator,
            "Only Synthetic creator can call this function."
        );
        _transfer(creator, shareholder, amount);
        if (balanceOf(creator) == 0) {
            state = SyntheticState.TOKENIZED;
        }
        return true;
    }

    //------------------------
    //  ISynthetic IMPL
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
        atState(SyntheticState.TOKENIZED)
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
        atState(SyntheticState.TOKENIZED)
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
        atState(SyntheticState.TOKENIZED)
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
        atState(SyntheticState.TOKENIZED)
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
        atState(SyntheticState.TOKENIZED)
        walletApproved(_msgSender())
        walletApproved(spender)
        walletApproved(address(this))
        returns (bool)
    {
        return super.decreaseAllowance(spender, subtractedValue);
    }

}

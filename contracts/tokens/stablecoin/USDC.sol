// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract USDC is ERC20 {

    uint8 private _precision;

    constructor(uint256 initialSupply, uint8 precision) ERC20("USD Coin", "USDC") {
        _mint(msg.sender, initialSupply);
        _precision = precision;
    }

    function decimals() public view virtual override returns (uint8) {
        return _precision;   // the same as the USDC
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { ISynthetic } from "./interfaces/ISynthetic.sol";
import { ICfManager } from "./interfaces/ICfManager.sol";

contract CfManager is ICfManager, Ownable {

    ISynthetic public synthetic;
    uint256 public minInvestment;
    uint256 public maxInvestment;
    uint256 public endsAt;

    constructor(uint256 _minInvestment, uint256 _maxInvestment, uint256 _endsAt) {
        require(
            _maxInvestment >= _minInvestment,
            "Max investment must be greater than or equal to min investment."
        );
        require(
            _endsAt > block.timestamp,
            "Ends at value has to be in the future."
        );
        minInvestment = _minInvestment;
        maxInvestment = _maxInvestment;
        endsAt = _endsAt;
    }

    function setSynthetic(address _synthetic) override external {
        ISynthetic synth = ISynthetic(_synthetic);
        require(
            address(synth) == address(0),
            "Synthetic address already set."
        );
        require(
            synth.totalShares() >= minInvestment,
            "Min investment must be less than total Synthetic value (shares)."
        );
        synthetic = synth;
    }

    function invest(uint256 amount) external {
        require(
            address(synthetic) != address(0),
            "Synthetic address not set."
        );
        IERC20 syntheticToken = IERC20(address(synthetic));
        IERC20 stablecoin = IERC20(synthetic.issuer().stablecoin());

        uint256 floatingShares = syntheticToken.balanceOf(address(this));
        uint256 newTotalInvestment = syntheticToken.balanceOf(msg.sender) + amount;
        uint256 adjustedMinInvestment = (floatingShares < minInvestment) ? floatingShares : minInvestment;
        
        require(
            floatingShares >= amount,
            "Investment amount bigger than the available shares."
        );
        require(
            newTotalInvestment >= adjustedMinInvestment,
            "Investment amount too low."
        );
        require(
            newTotalInvestment <= maxInvestment,
            "Investment amount too high."
        );

        stablecoin.transferFrom(msg.sender, address(this), amount);
        synthetic.addShareholder(msg.sender, amount);
    }

}

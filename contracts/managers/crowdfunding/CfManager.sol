// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IAsset } from "../../asset/IAsset.sol";
import { ICfManager } from "../crowdfunding/ICfManager.sol";

contract CfManager is ICfManager {

    address public owner;
    IAsset public asset;
    uint256 public minInvestment;
    uint256 public maxInvestment;
    uint256 public endsAt;

    constructor(address _owner, uint256 _minInvestment, uint256 _maxInvestment, uint256 _endsAt) {
        require(
            _minInvestment > 0,
            "Min investment must be greater than 0."
        );
        require(
            _maxInvestment >= _minInvestment,
            "Max investment must be greater than or equal to min investment."
        );
        require(
            _endsAt > block.timestamp,
            "Ends at value has to be in the future."
        );
        owner = _owner;
        minInvestment = _minInvestment;
        maxInvestment = _maxInvestment;
        endsAt = _endsAt;
    }

    function setAsset(address _assetAddress) override external {
        IAsset _asset = IAsset(_assetAddress);
        require(
            address(asset) == address(0),
            "Asset address already set."
        );
        require(
            _asset.totalShares() >= minInvestment,
            "Min investment must be less than total Asset value (shares)."
        );
        asset = _asset;
    }

    function invest(uint256 amount) external {
        require(
            address(asset) != address(0),
            "Asset address not set."
        );
        IERC20 assetToken = IERC20(address(asset));
        IERC20 stablecoin = IERC20(asset.issuer().stablecoin());

        uint256 floatingShares = assetToken.balanceOf(address(this));
        uint256 newTotalInvestment = assetToken.balanceOf(msg.sender) + amount;
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
        asset.addShareholder(msg.sender, amount);
    }

}

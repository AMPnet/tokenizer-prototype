// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { IAsset } from "../../asset/IAsset.sol";
import { ICfManager } from "../crowdfunding/ICfManager.sol";
import { AssetState } from "../../shared/Enums.sol";

contract CfManager is ICfManager {
    using SafeERC20 for IERC20;

    address public owner;
    IAsset public asset;
    uint256 public minInvestment;
    uint256 public maxInvestment;
    uint256 public endsAt;
    bool public finalized;

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

    modifier onlyOwner(address _wallet) {
        require(
            _wallet == owner,
            "Only owner can call this function."
        );
        _;
    }

    modifier assetInitialized() {
        require(
            address(asset) != address(0),
            "Asset address not set."
        );
        _;
    }

    modifier notFinalized() {
        require(
            !finalized,
            "The campaign is not finalized."
        );
        _;
    }

    modifier notExpired() {
        require(
            block.timestamp <= endsAt,
            "The campaign has expired."
        );
        _;
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

    function invest(uint256 amount) external assetInitialized notExpired {
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

        stablecoin.safeTransferFrom(msg.sender, address(this), amount);
        asset.addShareholder(msg.sender, amount);
    }

    function cancelInvestment() external assetInitialized notFinalized {
        IERC20 stablecoin = IERC20(asset.issuer().stablecoin());
        uint256 shares = IERC20(address(asset)).balanceOf(msg.sender);
        require(
            shares > 0,
            "No shares owned."
        );
        asset.removeShareholder(msg.sender, shares);
        stablecoin.safeTransfer(msg.sender, shares);
    }

    function finalize() external onlyOwner(msg.sender) assetInitialized notExpired notFinalized {
        require(
            IERC20(address(asset)).balanceOf(address(this)) == 0,
            "Can only finalize fully funded Assets."
        );
        asset.finalize();
        asset.setCreator(owner);
        finalized = true;
    }

}

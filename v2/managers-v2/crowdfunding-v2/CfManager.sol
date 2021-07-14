// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { IAsset } from "../../asset/IAsset.sol";
import { ICfManager } from "../crowdfunding/ICfManager.sol";
import { AssetFundingState } from "../../shared/Enums.sol";
import { CfManagerState, InfoEntry } from "../../shared/Structs.sol";

contract CfManager is ICfManager {
    using SafeERC20 for IERC20;

    //------------------------
    //  STATE
    //------------------------
    CfManagerState private state;
    InfoEntry[] private infoHistory;

    //------------------------
    //  EVENTS
    //------------------------
    event SetAsset(address asset);
    event Invest(address indexed investor, uint256 tokenAmount, uint256 tokenValue, uint256 timestamp);
    event CancelInvestment(address indexed investor, uint256 tokenAmount, uint256 tokenValue, uint256 timestamp);
    event Finalize(address indexed owner, uint256 timestamp);
    event SetInfo(string info, address setter);

    //------------------------
    //  CONSTRUCTOR
    //------------------------
    constructor(
        uint256 id,
        address owner,
        uint256 initialPricePerToken,
        uint256 minInvestment,
        uint256 maxInvestment,
        uint256 endsAt,
        string memory info
    ) {
        require(
            minInvestment > 0,
            "Min investment must be greater than 0."
        );
        require(
            maxInvestment >= minInvestment,
            "Max investment must be greater than or equal to min investment."
        );
        require(
            endsAt > block.timestamp,
            "Ends at value has to be in the future."
        );
        state = CfManagerState(
            id,
            owner,
            IAsset(address(0)),
            initialPricePerToken,
            minInvestment,
            maxInvestment,
            endsAt,
            false,
            info
        );
    }

    //------------------------
    //  MODIFIERS
    //------------------------
    modifier onlyOwner(address wallet) {
        require(
            wallet == state.owner,
            "Only owner can call this function."
        );
        _;
    }

    modifier assetInitialized() {
        require(
            address(state.asset) != address(0),
            "Asset address not set."
        );
        _;
    }

    modifier notFinalized() {
        require(
            !state.finalized,
            "The campaign is not finalized."
        );
        _;
    }

    modifier notExpired() {
        require(
            block.timestamp <= state.endsAt,
            "The campaign has expired."
        );
        _;
    }

    //------------------------
    //  STATE CHANGE FUNCTIONS
    //------------------------
    function setInfo(string memory info) external onlyOwner(msg.sender) {
        infoHistory.push(InfoEntry(
            info,
            block.timestamp
        ));
        state.info = info;
        emit SetInfo(info, msg.sender);
    }

    function invest(uint256 amount) external assetInitialized notExpired {
        IERC20 assetToken = _asset();
        IERC20 stablecoin = _stablecoin();

        uint256 floatingTokensValue = assetToken.balanceOf(address(this)) * state.initialPricePerToken;
        uint256 alreadyInvestedValue = assetToken.balanceOf(msg.sender) * state.initialPricePerToken;
        uint256 newInvestmentValue = (amount / state.initialPricePerToken) * state.initialPricePerToken;
        uint256 newInvestmentTokenAmount = newInvestmentValue / state.initialPricePerToken;
        uint256 newTotalInvestmentValue = alreadyInvestedValue + newInvestmentValue;
        uint256 adjustedMinInvestment = (floatingTokensValue < state.minInvestment) ? floatingTokensValue : state.minInvestment;
        
        require(
            floatingTokensValue >= newInvestmentValue,
            "Investment value bigger than the total available shares value."
        );
        require(
            newTotalInvestmentValue >= adjustedMinInvestment,
            "Investment amount too low."
        );
        require(
            newTotalInvestmentValue <= state.maxInvestment,
            "Investment amount too high."
        );

        stablecoin.safeTransferFrom(msg.sender, address(this), newInvestmentValue);
        state.asset.addShareholder(msg.sender, newInvestmentTokenAmount);
        emit Invest(msg.sender, newInvestmentTokenAmount, newInvestmentValue, block.timestamp);
    }

    function cancelInvestment() external assetInitialized notFinalized {
        IERC20 stablecoin = _stablecoin();
        uint256 shares = _asset().balanceOf(msg.sender);
        uint256 refund = shares * state.initialPricePerToken;
        require(
            shares > 0,
            "No shares owned."
        );
        state.asset.removeShareholder(msg.sender, shares);
        stablecoin.safeTransfer(msg.sender, refund);
        emit CancelInvestment(msg.sender, shares, refund, block.timestamp);
    }

    function finalize() external onlyOwner(msg.sender) assetInitialized notExpired notFinalized {
        require(
            _asset().balanceOf(address(this)) == 0,
            "Can only finalize fully funded Assets."
        );
        state.finalized = true;
        state.asset.finalize(state.owner);
        IERC20 stablecoin = _stablecoin();
        stablecoin.safeTransfer(msg.sender, stablecoin.balanceOf(address(this)));
        emit Finalize(msg.sender, block.timestamp);
    }

    //------------------------
    //  ICfManager IMPL
    //------------------------
    function setAsset(address assetAddress) external override {
        IAsset asset = IAsset(assetAddress);
        require(
            address(asset) == address(0),
            "Asset address already set."
        );
        state.asset = asset;
        emit SetAsset(assetAddress);
    }

    function getInfoHistory() external view override returns (InfoEntry[] memory) {
        return infoHistory;
    }

    //------------------------
    //  HELPERS
    //------------------------
    function _stablecoin() private view returns (IERC20) {
        return IERC20(
            state.asset.getState().issuer.getState().stablecoin
        );
    }

    function _asset() private view returns (IERC20) {
        return IERC20(
            address(state.asset)
        );
    }

}

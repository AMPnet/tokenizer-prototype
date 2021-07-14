// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { IAsset } from "../../asset/IAsset.sol";
import { ICfManagerSoftcap } from "../crowdfunding-softcap/ICfManagerSoftcap.sol";
import { AssetFundingState } from "../../shared/Enums.sol";
import { CfManagerSoftcapState, InfoEntry } from "../../shared/Structs.sol";

contract CfManagerSoftcap is ICfManagerSoftcap {
    using SafeERC20 for IERC20;

    //------------------------
    //  STATE
    //------------------------
    CfManagerSoftcapState private state;
    InfoEntry[] private infoHistory;
    mapping (address => uint256) claims;

    //------------------------
    //  EVENTS
    //------------------------
    event Invest(address indexed investor, uint256 tokenAmount, uint256 tokenValue, uint256 timestamp);
    event Claim(address indexed investor, uint256 tokenAmount, uint256 tookenValue, uint256 timestamp);
    event CancelInvestment(address indexed investor, uint256 tokenAmount, uint256 tokenValue, uint256 timestamp);
    event Finalize(address owner, uint256 totalFundsRaised, uint256 totalTokensSold, uint256 timestamp);
    event CancelCampaign(address owner, uint256 tokensReturned, uint256 timestamp);
    event SetInfo(string info, address setter);

    //------------------------
    //  CONSTRUCTOR
    //------------------------
    constructor(
        uint256 id,
        address owner,
        IAsset asset,
        uint256 initialPricePerToken,
        uint256 softCap,
        bool whitelistRequired,
        string memory info
    ) {
        require(
            softCap > 0,
            "Soft cap must be greater than 0."
        );
        require(
            initialPricePerToken > 0,
            "Initial price per token must be greater than 0."
        );
        state = CfManagerSoftcapState(
            id,
            owner,
            asset,
            initialPricePerToken,
            softCap,
            whitelistRequired,
            false,
            false,
            0,
            0,
            0,
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

    modifier active() {
        require(
            !state.cancelled,
            "The campaign has been cancelled."
        );
        _;
    }

    modifier finalized() {
        require(
            state.finalized,
            "The campaign is not finalized."
        );
        _;
    }

    modifier notFinalized() {
        require(
            !state.finalized,
            "The campaign is finalized."
        );
        _;
    }

    modifier isWhitelisted() {
        require(
            !state.whitelistRequired || (state.whitelistRequired && _walletApproved(msg.sender)),
            "Wallet not whitelisted."
        );
        _;
    }

    //------------------------
    // STATE CHANGE FUNCTIONS
    //------------------------
    function setInfo(string memory info) external onlyOwner(msg.sender) {
        infoHistory.push(InfoEntry(
            info,
            block.timestamp
        ));
        state.info = info;
        emit SetInfo(info, msg.sender);
    }

    function invest(uint256 amount) external active notFinalized isWhitelisted {
        require(amount > 0, "Investment amount has to be greater than 0.");

        IERC20 assetToken = _asset();
        IERC20 stablecoin = _stablecoin();

        uint256 investmentValue = (amount / state.initialPricePerToken) * state.initialPricePerToken;
        uint256 investmentTokenAmount = investmentValue / state.initialPricePerToken;
        uint256 totalTokenBalance = assetToken.balanceOf(address(this));

        require(
            investmentTokenAmount > 0,
            "Investment token amount has to be greater than 0"
        );
        require(
            totalTokenBalance >= (investmentTokenAmount + state.totalClaimableTokens),
            "No tokens available for this investment amount."
        );

        if (claims[msg.sender] == 0) {
            state.totalInvestorsCount += 1;
        }
        claims[msg.sender] += investmentTokenAmount;
        state.totalClaimableTokens +=  investmentTokenAmount;

        stablecoin.safeTransferFrom(msg.sender, address(this), investmentValue);
        emit Invest(msg.sender, investmentTokenAmount, investmentValue, block.timestamp);
    }

    function cancelInvestment() external notFinalized {
        IERC20 stablecoin = _stablecoin();
        uint256 investmentTokenAmount = claims[msg.sender];
        uint256 investmentValue = investmentTokenAmount * state.initialPricePerToken;
        require(
            investmentTokenAmount > 0,
            "No tokens owned."
        );
        claims[msg.sender] = 0;
        state.totalClaimableTokens -= investmentTokenAmount;
        state.totalInvestorsCount -= 1;
        stablecoin.safeTransfer(msg.sender, investmentValue);
        emit CancelInvestment(msg.sender, investmentTokenAmount, investmentValue, block.timestamp);
    }

    function claim() external finalized {
        uint256 claimableTokens = claims[msg.sender];
        uint256 claimableTokensValue = claimableTokens * state.initialPricePerToken;
        require(
            claimableTokens > 0,
            "No tokens owned."
        );
        state.totalClaimsCount += 1;
        claims[msg.sender] = 0;
        _asset().safeTransfer(msg.sender, claimableTokens);
        emit Claim(msg.sender, claimableTokens, claimableTokensValue, block.timestamp);
    }

    function finalize() external onlyOwner(msg.sender) notFinalized {
        IERC20 stablecoin = _stablecoin(); 
        IERC20 asset = _asset();
        require(
            stablecoin.balanceOf(address(this)) >= state.softCap,
            "Can only finalize campaign if the minimum funding goal has been reached."
        );
        state.finalized = true;
        uint256 fundsRaised = stablecoin.balanceOf(address(this));
        uint256 tokenRefund = asset.balanceOf(address(this)) - state.totalClaimableTokens;
        stablecoin.safeTransfer(msg.sender, fundsRaised);
        asset.safeTransfer(msg.sender, tokenRefund);
        emit Finalize(msg.sender, fundsRaised, state.totalClaimableTokens, block.timestamp);
    }

    function cancelCampaign() external onlyOwner(msg.sender) notFinalized {
        state.cancelled = true;
        uint256 tokenBalance = _asset().balanceOf(address(this));
        if(tokenBalance > 0) {
            _asset().safeTransfer(msg.sender, tokenBalance);
        }
        emit CancelCampaign(msg.sender, tokenBalance, block.timestamp);
    }

    //------------------------
    //  ICfManagerSoftcap IMPL
    //------------------------
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

    function _walletApproved(address wallet) private view returns (bool) {
        return state.asset.getState().issuer.isWalletApproved(wallet);
    }

}

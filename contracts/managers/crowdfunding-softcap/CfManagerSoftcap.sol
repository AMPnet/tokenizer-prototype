// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../../asset/IAsset.sol";
import "../../issuer/IIssuer.sol";
import "../crowdfunding-softcap/ICfManagerSoftcap.sol";
import "../../shared/Structs.sol";

contract CfManagerSoftcap is ICfManagerSoftcap {
    using SafeERC20 for IERC20;

    //------------------------
    //  CONSTANTS
    //------------------------
    uint256 constant PRICE_DECIMALS_PRECISION = 10 ** 4;
    uint256 constant STABLECOIN_DECIMALS_PRECISION = 10 ** 18;

    //------------------------
    //  STATE
    //------------------------
    Structs.CfManagerSoftcapState private state;
    Structs.InfoEntry[] private infoHistory;
    mapping (address => uint256) claims;

    //------------------------
    //  EVENTS
    //------------------------
    event Invest(address indexed investor, uint256 tokenAmount, uint256 tokenValue, uint256 timestamp);
    event Claim(address indexed investor, uint256 tokenAmount, uint256 tokenValue, uint256 timestamp);
    event CancelInvestment(address indexed investor, uint256 tokenAmount, uint256 tokenValue, uint256 timestamp);
    event Finalize(address owner, uint256 totalFundsRaised, uint256 totalTokensSold, uint256 timestamp);
    event CancelCampaign(address owner, uint256 tokensReturned, uint256 timestamp);
    event SetInfo(string info, address setter, uint256 timestamp);

    //------------------------
    //  CONSTRUCTOR
    //------------------------
    constructor(
        uint256 id,
        address owner,
        address asset,
        uint256 tokenPrice,
        uint256 softCap,
        bool whitelistRequired,
        string memory info
    ) {
        require(
            tokenPrice > 0,
            "Initial price per token must be greater than 0."
        );
        state = Structs.CfManagerSoftcapState(
            id,
            owner,
            asset,
            tokenPrice,
            softCap,
            whitelistRequired,
            false,
            false,
            0, 0, 0, 0,
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
    function invest(uint256 amount) external active notFinalized isWhitelisted {
        require(amount > 0, "Investment amount has to be greater than 0.");

        IERC20 assetToken = _assetERC20();
        IERC20 stablecoin = _stablecoin();

        uint256 totalTokenBalance = assetToken.balanceOf(address(this));
        uint256 floatingTokens = totalTokenBalance - state.totalClaimableTokens;
        require(floatingTokens > 0, "No more tokens available for sale.");

        uint256 tokenAmount = 
            (amount / state.tokenPrice) 
                * PRICE_DECIMALS_PRECISION 
                * _asset_decimals_precision() 
                / STABLECOIN_DECIMALS_PRECISION;
        uint256 tokenValue = _token_value(tokenAmount);
        require(tokenAmount > 0 && tokenValue > 0, "Investment amount too low.");
        require(floatingTokens >= tokenAmount, "Not enough tokens left for this investment amount.");

        if (claims[msg.sender] == 0) {
            state.totalInvestorsCount += 1;
        }
        claims[msg.sender] += tokenAmount;
        state.totalClaimableTokens += tokenAmount;
        state.totalFundsRaised += tokenValue;
        
        stablecoin.safeTransferFrom(msg.sender, address(this), tokenValue);
        emit Invest(msg.sender, tokenAmount, tokenValue, block.timestamp);
    }

    function cancelInvestment() external notFinalized {
        IERC20 stablecoin = _stablecoin();
        uint256 tokenAmount = claims[msg.sender];
        uint256 tokenValue = _token_value(tokenAmount);
        require(
            tokenAmount > 0,
            "No tokens owned."
        );
        claims[msg.sender] = 0;
        state.totalClaimableTokens -= tokenAmount;
        state.totalInvestorsCount -= 1;
        state.totalFundsRaised -= tokenValue;
        stablecoin.safeTransfer(msg.sender, tokenValue);
        emit CancelInvestment(msg.sender, tokenAmount, tokenValue, block.timestamp);
    }

    function claim() external finalized {
        uint256 claimableTokens = claims[msg.sender];
        uint256 claimableTokensValue = _token_value(claimableTokens);
        require(
            claimableTokens > 0,
            "No tokens owned."
        );
        state.totalClaimsCount += 1;
        claims[msg.sender] = 0;
        _assetERC20().safeTransfer(msg.sender, claimableTokens);
        emit Claim(msg.sender, claimableTokens, claimableTokensValue, block.timestamp);
    }

    function finalize() external onlyOwner(msg.sender) notFinalized {
        IERC20 stablecoin = _stablecoin(); 
        IERC20 asset = _assetERC20();
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
        uint256 tokenBalance = _assetERC20().balanceOf(address(this));
        if(tokenBalance > 0) {
            _assetERC20().safeTransfer(msg.sender, tokenBalance);
        }
        emit CancelCampaign(msg.sender, tokenBalance, block.timestamp);
    }

    //------------------------
    //  ICfManagerSoftcap IMPL
    //------------------------
    function setInfo(string memory info) external override onlyOwner(msg.sender) {
        infoHistory.push(Structs.InfoEntry(
            info,
            block.timestamp
        ));
        state.info = info;
        emit SetInfo(info, msg.sender, block.timestamp);
    }

    function getInfoHistory() external view override returns (Structs.InfoEntry[] memory) {
        return infoHistory;
    }

    function getState() external view override returns (Structs.CfManagerSoftcapState memory) {
        return state;
    }

    //------------------------
    //  HELPERS
    //------------------------
    function _stablecoin() private view returns (IERC20) {
        return IERC20(_issuer().getState().stablecoin);
    }

    function _issuer() private view returns (IIssuer) {
        return IIssuer(_asset().getState().issuer);
    }

    function _asset() private view returns (IAsset) {
        return IAsset(state.asset);   
    }

    function _assetERC20() private view returns (IERC20) {
        return IERC20(address(state.asset));
    }

    function _asset_decimals_precision() private view returns (uint256) {
        return 10 ** IAsset(address(state.asset)).getDecimals();
    }

    function _token_value(uint256 tokenAmount) private view returns (uint256) {
        return tokenAmount
                    * state.tokenPrice
                    * STABLECOIN_DECIMALS_PRECISION
                    / (_asset_decimals_precision() * PRICE_DECIMALS_PRECISION);
    }

    function _walletApproved(address wallet) private view returns (bool) {
        return _issuer().isWalletApproved(wallet);
    }

}

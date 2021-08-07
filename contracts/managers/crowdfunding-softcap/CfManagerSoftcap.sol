// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../../asset/IAsset.sol";
import "../../issuer/IIssuer.sol";
import "../../tokens/IToken.sol";
import "../crowdfunding-softcap/ICfManagerSoftcap.sol";
import "../../shared/Structs.sol";

contract CfManagerSoftcap is ICfManagerSoftcap {
    using SafeERC20 for IERC20;

    //------------------------
    //  CONSTANTS
    //------------------------
    uint256 constant PRICE_DECIMALS_PRECISION = 10 ** 4;

    //------------------------
    //  STATE
    //------------------------
    Structs.CfManagerSoftcapState private state;
    Structs.InfoEntry[] private infoHistory;
    mapping (address => uint256) public override claims;
    mapping (address => uint256) public override investments;
    mapping (address => uint256) public override tokenAmounts;

    //------------------------
    //  EVENTS
    //------------------------
    event Invest(address indexed investor, uint256 tokenAmount, uint256 tokenValue, uint256 timestamp);
    event Claim(address indexed investor, uint256 tokenAmount, uint256 tokenValue, uint256 timestamp);
    event CancelInvestment(address indexed investor, uint256 tokenAmount, uint256 tokenValue, uint256 timestamp);
    event Finalize(
        address indexed owner,
        uint256 fundsRaised,
        uint256 tokensSold,
        uint256 tokensRefund,
        uint256 timestamp
    );
    event CancelCampaign(address indexed owner, uint256 tokensReturned, uint256 timestamp);
    event SetInfo(string info, address setter, uint256 timestamp);
    event ChangeOwnership(address caller, address newOwner, uint256 timestamp);

    //------------------------
    //  CONSTRUCTOR
    //------------------------
    constructor(
        uint256 id,
        address owner,
        string memory ansName,
        uint256 ansId,
        address asset,
        uint256 tokenPrice,
        uint256 softCap,
        uint256 minInvestment,
        uint256 maxInvestment,
        bool whitelistRequired,
        string memory info
    ) {
        require(owner != address(0), "CfManagerSoftcap: Invalid owner address");
        require(asset != address(0), "CfManagerSoftcap: Invalid asset address");
        require(tokenPrice > 0, "CfManagerSoftcap: Initial price per token must be greater than 0.");
        require(maxInvestment >= minInvestment, "CfManagerSoftcap: Max has to be bigger than min investment");
        address issuer = address(IAsset(asset).getState().issuer);
        state = Structs.CfManagerSoftcapState(
            id,
            address(this),
            ansName,
            ansId,
            msg.sender,
            owner,
            asset,
            issuer,
            tokenPrice,
            softCap,
            minInvestment,
            maxInvestment,
            whitelistRequired,
            false,
            false,
            0, 0, 0, 0, 0, 0,
            info
        );
    }

    //------------------------
    //  MODIFIERS
    //------------------------
    modifier ownerOnly() {
        require(
            msg.sender == state.owner,
            "CfManagerSoftcap: Only owner can call this function."
        );
        _;
    }

    modifier active() {
        require(
            !state.cancelled,
            "CfManagerSoftcap: The campaign has been cancelled."
        );
        _;
    }

    modifier finalized() {
        require(
            state.finalized,
            "CfManagerSoftcap: The campaign is not finalized."
        );
        _;
    }

    modifier notFinalized() {
        require(
            !state.finalized,
            "CfManagerSoftcap: The campaign is finalized."
        );
        _;
    }

    modifier isWhitelisted() {
        require(
            !state.whitelistRequired || (state.whitelistRequired && _walletApproved(msg.sender)),
            "CfManagerSoftcap: Wallet not whitelisted."
        );
        _;
    }

    //------------------------
    // STATE CHANGE FUNCTIONS
    //------------------------
    function invest(uint256 amount) external active notFinalized isWhitelisted {
        require(amount > 0, "Investment amount has to be greater than 0.");

        uint256 floatingTokens = _assetERC20().balanceOf(address(this)) - state.totalClaimableTokens;
        require(floatingTokens > 0, "CfManagerSoftcap: No more tokens available for sale.");

        uint256 tokenAmount = 
            (amount / state.tokenPrice) 
                * PRICE_DECIMALS_PRECISION 
                * _asset_decimals_precision() 
                / _stablecoin_decimals_precision();
        uint256 tokenValue = _token_value(tokenAmount);
        require(tokenAmount > 0 && tokenValue > 0, "CfManagerSoftcap: Investment amount too low.");
        require(floatingTokens >= tokenAmount, "CfManagerSoftcap: Not enough tokens left for this investment amount.");
        _stablecoin().safeTransferFrom(msg.sender, address(this), tokenValue);
        
        uint256 totalInvestmentValue = _token_value(tokenAmount + claims[msg.sender]);
        require(
            totalInvestmentValue >= _adjusted_min_investment(floatingTokens),
            "CfManagerSoftcap: Investment amount too low."
        );
        require(
            totalInvestmentValue <= state.maxInvestment,
            "CfManagerSoftcap: Investment amount too high."
        );

        if (claims[msg.sender] == 0) {
            state.totalInvestorsCount += 1;
        }
        claims[msg.sender] += tokenAmount;
        investments[msg.sender] += tokenValue;
        tokenAmounts[msg.sender] += tokenAmount;
        state.totalClaimableTokens += tokenAmount;
        state.totalTokensSold += tokenAmount;
        state.totalFundsRaised += tokenValue;
        emit Invest(msg.sender, tokenAmount, tokenValue, block.timestamp);
    }

    function cancelInvestment() external notFinalized {
        uint256 tokenAmount = claims[msg.sender];
        uint256 tokenValue = investments[msg.sender];
        require(
            tokenAmount > 0 && tokenValue > 0,
            "CfManagerSoftcap: No tokens owned."
        );
        state.totalInvestorsCount -= 1;
        claims[msg.sender] = 0;
        investments[msg.sender] = 0;
        tokenAmounts[msg.sender] = 0;
        state.totalClaimableTokens -= tokenAmount;
        state.totalTokensSold -= tokenAmount;
        state.totalFundsRaised -= tokenValue;
        _stablecoin().safeTransfer(msg.sender, tokenValue);
        emit CancelInvestment(msg.sender, tokenAmount, tokenValue, block.timestamp);
    }

    function claim(address investor) external finalized {
        uint256 claimableTokens = claims[investor];
        uint256 claimableTokensValue = investments[investor];
        require(
            claimableTokens > 0 && claimableTokensValue > 0,
            "CfManagerSoftcap: No tokens owned."
        );
        state.totalClaimsCount += 1;
        state.totalClaimableTokens -= claimableTokens;
        claims[investor] = 0;
        _assetERC20().safeTransfer(investor, claimableTokens);
        emit Claim(investor, claimableTokens, claimableTokensValue, block.timestamp);
    }

    function finalize() external ownerOnly active notFinalized {
        IERC20 stablecoin = _stablecoin();
        require(
            stablecoin.balanceOf(address(this)) >= state.softCap,
            "CfManagerSoftcap: Can only finalize campaign if the minimum funding goal has been reached."
        );
        state.finalized = true;  
        IERC20 assetERC20 = _assetERC20();
        uint256 fundsRaised = stablecoin.balanceOf(address(this));
        uint256 tokensSold = state.totalTokensSold;
        uint256 tokensRefund = assetERC20.balanceOf(address(this)) - tokensSold;
        IAsset asset = _asset();
        asset.finalizeSale(tokensSold, fundsRaised);
        stablecoin.safeTransfer(msg.sender, fundsRaised);
        assetERC20.safeTransfer(msg.sender, tokensRefund);
        emit Finalize(msg.sender, fundsRaised, tokensSold, tokensRefund, block.timestamp);
    }

    function cancelCampaign() external ownerOnly active notFinalized {
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
    function setInfo(string memory info) external override ownerOnly {
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
        Structs.CfManagerSoftcapState memory stateWithBalance = state; 
        stateWithBalance.totalTokensBalance = _assetERC20().balanceOf(address(this));
        return stateWithBalance;
    }

    function changeOwnership(address newOwner) external override ownerOnly {
        state.owner = newOwner;
        emit ChangeOwnership(msg.sender, newOwner, block.timestamp);
    }

    //------------------------
    //  HELPERS
    //------------------------
    function _stablecoin() private view returns (IERC20) {
        return IERC20(_issuer().getState().stablecoin);
    }

    function _issuer() private view returns (IIssuer) {
        return IIssuer(state.issuer);
    }

    function _asset() private view returns (IAsset) {
        return IAsset(state.asset);   
    }

    function _assetERC20() private view returns (IERC20) {
        return IERC20(state.asset);
    }

    function _asset_decimals_precision() private view returns (uint256) {
        return 10 ** IAsset(state.asset).getDecimals();
    }

    function _stablecoin_decimals_precision() private view returns (uint256) {
        return 10 ** IToken(_issuer().getState().stablecoin).decimals();
    }

    function _token_value(uint256 tokenAmount) private view returns (uint256) {
        return tokenAmount
                    * state.tokenPrice
                    * _stablecoin_decimals_precision()
                    / (_asset_decimals_precision() * PRICE_DECIMALS_PRECISION);
    }

    function _walletApproved(address wallet) private view returns (bool) {
        return _issuer().isWalletApproved(wallet);
    }

    function _adjusted_min_investment(uint256 remainingTokens) private view returns (uint256) {
        uint256 remainingTokensValue = _token_value(remainingTokens);
        return (remainingTokensValue < state.minInvestment) ? remainingTokensValue : state.minInvestment;
    }

}

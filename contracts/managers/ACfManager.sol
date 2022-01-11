// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../shared/Structs.sol";
import "../tokens/erc20/IToken.sol";
import "../shared/IAssetCommon.sol";
import "../shared/IIssuerCommon.sol";
import "./IACfManager.sol";

abstract contract ACfManager is IVersioned, IACfManager {
    using SafeERC20 for IERC20;

    //------------------------
    //  STATE
    //------------------------
    Structs.CfManagerState internal state;
    Structs.InfoEntry[] internal infoHistory;
    mapping (address => uint256) internal claims;
    mapping (address => uint256) internal investments;
    mapping (address => uint256) internal tokenAmounts;

    //------------------------
    //  EVENTS
    //------------------------
    event Invest(
        address indexed investor,
        address asset,
        uint256 tokenAmount,
        uint256 tokenValue,
        uint256 timestamp
    );
    event Claim(
        address indexed investor,
        address asset,
        uint256 tokenAmount,
        uint256 tokenValue,
        uint256 timestamp
    );
    event CancelInvestment(
        address indexed investor,
        address asset,
        uint256 tokenAmount,
        uint256 tokenValue,
        uint256 timestamp
    );
    event Finalize(
        address indexed owner,
        address asset,
        uint256 fundsRaised,
        uint256 tokensSold,
        uint256 tokensRefund,
        uint256 timestamp
    );
    event CancelCampaign(address indexed owner, address asset, uint256 tokensReturned, uint256 timestamp);
    event SetInfo(string info, address setter, uint256 timestamp);
    event ChangeOwnership(address caller, address newOwner, uint256 timestamp);

    //------------------------
    //  MODIFIERS
    //------------------------
    modifier ownerOnly() {
        require(
            msg.sender == state.owner,
            "ACfManager: Only owner can call this function."
        );
        _;
    }

    modifier active() {
        require(
            !state.canceled,
            "ACfManager: The campaign has been canceled."
        );
        _;
    }

    modifier finalized() {
        require(
            state.finalized,
            "ACfManager: The campaign is not finalized."
        );
        _;
    }

    modifier notFinalized() {
        require(
            !state.finalized,
            "ACfManager: The campaign is finalized."
        );
        _;
    }

    modifier isWhitelisted(address investor) {
        require(
            isWalletWhitelisted(investor),
            "ACfManager: Wallet not whitelisted."
        );
        _;
    }

    //------------------------
    // STATE CHANGE FUNCTIONS
    //------------------------
    function invest(uint256 amount) external {
        _invest(msg.sender, msg.sender, amount);
    }

    function investForBeneficiary(address spender, address beneficiary, uint256 amount) external {
        if (spender != beneficiary) {
            require(
                spender == msg.sender,
                "ACfManager: Only spender can decide to book the investment on someone else."
            );
        }
        _invest(spender, beneficiary, amount);
    }

    function cancelInvestment() external notFinalized {
        _cancel_investment(msg.sender);
    }

    function cancelInvestmentFor(address investor) external {
        require(
            state.canceled,
            "ACfManager: Can only cancel for someone if the campaign has been canceled."
        );
        _cancel_investment(investor);
    }

    function finalize() external ownerOnly active notFinalized {
        IERC20 sc = stablecoin();
        uint256 fundsRaised = sc.balanceOf(address(this));
        require(
            fundsRaised >= state.softCap || _token_value_to_soft_cap() == 0,
            "ACfManager: Can only finalize campaign if the minimum funding goal has been reached."
        );
        state.finalized = true;
        IERC20 assetERC20 = _assetERC20();
        uint256 tokensSold = state.totalTokensSold;
        uint256 tokensRefund = assetERC20.balanceOf(address(this)) - tokensSold;
        IAssetCommon(state.asset).finalizeSale();
        if (fundsRaised > 0) {
            (address treasury, uint256 fee) = _calculateFee();
            if (fee > 0 && treasury != address(0)) {
                sc.safeTransfer(treasury, fee);
                sc.safeTransfer(msg.sender, fundsRaised - fee);
            } else {
                sc.safeTransfer(msg.sender, fundsRaised);
            }
        }
        if (tokensRefund > 0) { assetERC20.safeTransfer(msg.sender, tokensRefund); }
        emit Finalize(msg.sender, state.asset, fundsRaised, tokensSold, tokensRefund, block.timestamp);
    }

    function cancelCampaign() external ownerOnly active notFinalized {
        state.canceled = true;
        uint256 tokenBalance = _assetERC20().balanceOf(address(this));
        if(tokenBalance > 0) { _assetERC20().safeTransfer(msg.sender, tokenBalance); }
        emit CancelCampaign(msg.sender, state.asset, tokenBalance, block.timestamp);
    }

    function flavor() external view override returns (string memory) { return state.flavor; }

    function version() external view override returns (string memory) { return state.version; }

    function commonState() external view override returns (Structs.CampaignCommonState memory) {
        return Structs.CampaignCommonState(
            state.flavor,
            state.version,
            state.contractAddress,
            state.owner,
            state.info,
            state.asset,
            state.stablecoin,
            state.softCap,
            state.finalized,
            state.canceled,
            state.tokenPrice,
            state.totalFundsRaised,
            state.totalTokensSold
        );
    }
    function investmentAmount(address investor) external view override returns (uint256) {
        return investments[investor];
    }
    function tokenAmount(address investor) external view override returns (uint256) { return tokenAmounts[investor]; }
    function claimedAmount(address investor) external view override returns (uint256) { return claims[investor]; }

    function setInfo(string memory info) external override ownerOnly {
        infoHistory.push(Structs.InfoEntry(
            info,
            block.timestamp
        ));
        state.info = info;
        emit SetInfo(info, msg.sender, block.timestamp);
    }

    function getInfoHistory() external override view returns (Structs.InfoEntry[] memory) {
        return infoHistory;
    }

    function changeOwnership(address newOwner) external override ownerOnly {
        state.owner = newOwner;
        emit ChangeOwnership(msg.sender, newOwner, block.timestamp);
    }

    function isWalletWhitelisted(address wallet) public view returns (bool) {
        return !state.whitelistRequired || (state.whitelistRequired && _walletApproved(wallet));
    }

    function stablecoin() public view returns (IERC20) {
        return IERC20(state.stablecoin);
    }

    //------------------------
    //  HELPERS
    //------------------------
    function _invest(address spender, address investor, uint256 amount) internal active notFinalized isWhitelisted(investor) {
        require(amount > 0, "ACfManager: Investment amount has to be greater than 0.");
        uint256 tokenBalance = _assetERC20().balanceOf(address(this));
        require(
            _token_value(tokenBalance, state.tokenPrice, state.asset) >= state.softCap,
            "ACfManager: not enough tokens for sale to reach the softcap."
        );
        uint256 floatingTokens = tokenBalance - state.totalClaimableTokens;

        uint256 tokens = _token_amount_for_investment(amount, state.tokenPrice, state.asset);
        uint256 tokenValue = _token_value(tokens, state.tokenPrice, state.asset);
        require(tokens > 0 && tokenValue > 0, "ACfManager: Investment amount too low.");
        require(floatingTokens >= tokens, "ACfManager: Not enough tokens left for this investment amount.");
        uint256 totalInvestmentValue = _token_value(tokens + claims[investor], state.tokenPrice, state.asset);
        require(
            totalInvestmentValue >= _adjusted_min_investment(floatingTokens),
            "ACfManager: Investment amount too low."
        );
        require(
            totalInvestmentValue <= state.maxInvestment,
            "ACfManager: Investment amount too high."
        );

        stablecoin().safeTransferFrom(spender, address(this), tokenValue);

        if (claims[investor] == 0) {
            state.totalInvestorsCount += 1;
        }
        claims[investor] += tokens;
        investments[investor] += tokenValue;
        tokenAmounts[investor] += tokens;
        state.totalClaimableTokens += tokens;
        state.totalTokensSold += tokens;
        state.totalFundsRaised += tokenValue;
        emit Invest(investor, state.asset, tokens, tokenValue, block.timestamp);
    }

    function _cancel_investment(address investor) internal {
        uint256 tokens = claims[investor];
        uint256 tokenValue = investments[investor];
        require(
            tokens > 0 && tokenValue > 0,
            "ACfManager: No tokens owned."
        );
        state.totalInvestorsCount -= 1;
        claims[investor] = 0;
        investments[investor] = 0;
        tokenAmounts[investor] = 0;
        state.totalClaimableTokens -= tokens;
        state.totalTokensSold -= tokens;
        state.totalFundsRaised -= tokenValue;
        stablecoin().safeTransfer(investor, tokenValue);
        emit CancelInvestment(investor, state.asset, tokens, tokenValue, block.timestamp);
    }

    function _calculateFee() internal returns (address, uint256) {
        (bool success, bytes memory result) = state.feeManager.call(
            abi.encodeWithSignature("calculateFee(address)", address(this))
        );
        if (success) {
            return abi.decode(result, (address, uint256));
        } else { return (address(0), 0); }
    }

    function _assetERC20() internal view returns (IERC20) {
        return IERC20(state.asset);
    }

    function _asset_decimals_precision(address asset) internal view returns (uint256) {
        return 10 ** IToken(asset).decimals();
    }

    function _asset_price_precision(address asset) internal view returns (uint256) {
        return IAssetCommon(asset).priceDecimalsPrecision();
    }

    function _stablecoin_decimals_precision(address stable) internal view returns (uint256) {
        return 10 ** IToken(stable).decimals();
    }

    function _token_value(uint256 tokens, uint256 tokenPrice, address asset) internal view returns (uint256) {
        address stable = IIssuerCommon(IAssetCommon(asset).commonState().issuer).commonState().stablecoin;
        return tokens
        * tokenPrice
        * _stablecoin_decimals_precision(stable)
        / _asset_price_precision(asset)
        / _asset_decimals_precision(asset);
    }

    function _walletApproved(address wallet) internal view returns (bool) {
        return IIssuerCommon(state.issuer).isWalletApproved(wallet);
    }

    function _adjusted_min_investment(uint256 remainingTokens) internal view returns (uint256) {
        uint256 remainingTokensValue = _token_value(remainingTokens, state.tokenPrice, state.asset);
        return (remainingTokensValue < state.minInvestment) ? remainingTokensValue : state.minInvestment;
    }

    function _token_value_to_soft_cap() private view returns (uint256) {
        uint256 tokenAmountForInvestment = _token_amount_for_investment(
            state.softCap - state.totalFundsRaised,
            state.tokenPrice,
            state.asset
        );
        return _token_value(tokenAmountForInvestment, state.tokenPrice, state.asset);
    }

    function _token_amount_for_investment(
        uint256 investment,
        uint256 tokenPrice,
        address asset
    ) internal view returns (uint256) {
        address stable = IIssuerCommon(IAssetCommon(asset).commonState().issuer).commonState().stablecoin;
        return investment
        * _asset_price_precision(asset)
        * _asset_decimals_precision(asset)
        / tokenPrice
        / _stablecoin_decimals_precision(stable);
    }
}

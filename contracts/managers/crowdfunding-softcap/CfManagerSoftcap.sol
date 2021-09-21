// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../../asset/IAsset.sol";
import "../../issuer/IIssuer.sol";
import "../../tokens/erc20/IToken.sol";
import "../crowdfunding-softcap/ICfManagerSoftcap.sol";
import "../../shared/Structs.sol";
import "../../shared/IAssetCommon.sol";

contract CfManagerSoftcap is ICfManagerSoftcap {
    using SafeERC20 for IERC20;

    //------------------------
    //  STATE
    //------------------------
    Structs.CfManagerSoftcapState private state;
    Structs.InfoEntry[] private infoHistory;
    mapping (address => uint256) private claims;
    mapping (address => uint256) private investments;
    mapping (address => uint256) private tokenAmounts;

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
    //  CONSTRUCTOR
    //------------------------
    constructor(
        string memory contractFlavor,
        string memory contractVersion,
        address owner,
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
        require(maxInvestment >= minInvestment, "CfManagerSoftcap: Max has to be bigger than min investment.");
        require(maxInvestment > 0, "CfManagerSoftcap: Max investment has to be bigger than 0.");
        address issuer = address(IAssetCommon(asset).commonState().issuer);
        state = Structs.CfManagerSoftcapState(
            contractFlavor,
            contractVersion,
            address(this),
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
        require(
            _token_value(IToken(asset).totalSupply()) >= softCap,
            "CfManagerSoftcap: Invalid soft cap."
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
            !state.canceled,
            "CfManagerSoftcap: The campaign has been canceled."
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

        uint256 tokens = 
            (amount / state.tokenPrice) 
                * _asset_price_precision()
                * _asset_decimals_precision() 
                / _stablecoin_decimals_precision();
        uint256 tokenValue = _token_value(tokens);
        require(tokens > 0 && tokenValue > 0, "CfManagerSoftcap: Investment amount too low.");
        require(floatingTokens >= tokens, "CfManagerSoftcap: Not enough tokens left for this investment amount.");        
        uint256 totalInvestmentValue = _token_value(tokens + claims[msg.sender]);
        require(
            totalInvestmentValue >= _adjusted_min_investment(floatingTokens),
            "CfManagerSoftcap: Investment amount too low."
        );
        require(
            totalInvestmentValue <= state.maxInvestment,
            "CfManagerSoftcap: Investment amount too high."
        );

        _stablecoin().safeTransferFrom(msg.sender, address(this), tokenValue);

        if (claims[msg.sender] == 0) {
            state.totalInvestorsCount += 1;
        }
        claims[msg.sender] += tokens;
        investments[msg.sender] += tokenValue;
        tokenAmounts[msg.sender] += tokens;
        state.totalClaimableTokens += tokens;
        state.totalTokensSold += tokens;
        state.totalFundsRaised += tokenValue;
        emit Invest(msg.sender, state.asset, tokens, tokenValue, block.timestamp);
    }

    function cancelInvestment() external notFinalized {
        uint256 tokens = claims[msg.sender];
        uint256 tokenValue = investments[msg.sender];
        require(
            tokens > 0 && tokenValue > 0,
            "CfManagerSoftcap: No tokens owned."
        );
        state.totalInvestorsCount -= 1;
        claims[msg.sender] = 0;
        investments[msg.sender] = 0;
        tokenAmounts[msg.sender] = 0;
        state.totalClaimableTokens -= tokens;
        state.totalTokensSold -= tokens;
        state.totalFundsRaised -= tokenValue;
        _stablecoin().safeTransfer(msg.sender, tokenValue);
        emit CancelInvestment(msg.sender, state.asset, tokens, tokenValue, block.timestamp);
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
        emit Claim(investor, state.asset, claimableTokens, claimableTokensValue, block.timestamp);
    }

    function finalize() external ownerOnly active notFinalized {
        IERC20 stablecoin = _stablecoin();
        uint256 fundsRaised = stablecoin.balanceOf(address(this));
        require(
            fundsRaised >= state.softCap,
            "CfManagerSoftcap: Can only finalize campaign if the minimum funding goal has been reached."
        );
        state.finalized = true;  
        IERC20 assetERC20 = _assetERC20();
        uint256 tokensSold = state.totalTokensSold;
        uint256 tokensRefund = assetERC20.balanceOf(address(this)) - tokensSold;
        IAssetCommon(state.asset).finalizeSale();
        stablecoin.safeTransfer(msg.sender, fundsRaised);
        assetERC20.safeTransfer(msg.sender, tokensRefund);
        emit Finalize(msg.sender, state.asset, fundsRaised, tokensSold, tokensRefund, block.timestamp);
    }

    function cancelCampaign() external ownerOnly active notFinalized {
        state.canceled = true;
        uint256 tokenBalance = _assetERC20().balanceOf(address(this));
        if(tokenBalance > 0) {
            _assetERC20().safeTransfer(msg.sender, tokenBalance);
        }
        emit CancelCampaign(msg.sender, state.asset, tokenBalance, block.timestamp);
    }

    //------------------------
    //  ICfManagerSoftcap IMPL
    //------------------------
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
            state.softCap,
            state.finalized,
            state.canceled,
            state.tokenPrice,
            state.totalFundsRaised,
            state.totalTokensSold
        );
    }

    function investmentAmount(address investor) external view override returns (uint256) { return investments[investor]; }
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

    function _assetERC20() private view returns (IERC20) {
        return IERC20(state.asset);
    }

    function _asset_decimals_precision() private view returns (uint256) {
        return 10 ** IToken(state.asset).decimals();
    }

    function _asset_price_precision() private view returns (uint256) {
        return IAssetCommon(state.asset).priceDecimalsPrecision();
    }

    function _stablecoin_decimals_precision() private view returns (uint256) {
        return 10 ** IToken(_issuer().getState().stablecoin).decimals();
    }

    function _token_value(uint256 tokens) private view returns (uint256) {
        return tokens
                    * state.tokenPrice
                    * _stablecoin_decimals_precision()
                    / (_asset_decimals_precision() * _asset_price_precision());
    }

    function _walletApproved(address wallet) private view returns (bool) {
        return _issuer().isWalletApproved(wallet);
    }

    function _adjusted_min_investment(uint256 remainingTokens) private view returns (uint256) {
        uint256 remainingTokensValue = _token_value(remainingTokens);
        return (remainingTokensValue < state.minInvestment) ? remainingTokensValue : state.minInvestment;
    }

}

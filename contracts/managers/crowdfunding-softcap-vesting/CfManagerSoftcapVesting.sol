// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./ICfManagerSoftcapVesting.sol";
import "../../tokens/erc20/IToken.sol";
import "../../shared/IAssetCommon.sol";
import "../../shared/IIssuerCommon.sol";
import "../../shared/Structs.sol";

contract CfManagerSoftcapVesting is ICfManagerSoftcapVesting {
    using SafeERC20 for IERC20;

    //------------------------
    //  STATE
    //------------------------
    Structs.CfManagerSoftcapVestingState private state;
    Structs.InfoEntry[] private infoHistory;
    mapping (address => uint256) private claims;
    mapping (address => uint256) private investments;
    mapping (address => uint256) private tokenAmounts;
    mapping (address => uint256) private released;

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
    event StartVesting(
        address indexed owner,
        address asset,
        uint256 start,
        uint256 cliffDuration,
        uint256 duration,
        uint256 timestamp
    );
    event Revoke(
        address indexed owner,
        address asset,
        uint256 amount,
        uint256 timestamp
    );

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
        require(owner != address(0), "CfManagerSoftcapVesting: Invalid owner address");
        require(asset != address(0), "CfManagerSoftcapVesting: Invalid asset address");
        require(tokenPrice > 0, "CfManagerSoftcapVesting: Initial price per token must be greater than 0.");
        require(maxInvestment >= minInvestment, "CfManagerSoftcapVesting: Max has to be bigger than min investment.");
        require(maxInvestment > 0, "CfManagerSoftcapVesting: Max investment has to be bigger than 0.");
        IIssuerCommon issuer = IIssuerCommon(IAssetCommon(asset).commonState().issuer);
        state = Structs.CfManagerSoftcapVestingState(
            contractFlavor,
            contractVersion,
            address(this),
            owner,
            asset,
            address(issuer),
            issuer.commonState().stablecoin,
            tokenPrice,
            softCap,
            minInvestment,
            maxInvestment,
            whitelistRequired,
            false,
            false,
            0, 0, 0, 0, 0,
            info,
            false, 0, 0, 0, true, false
        );
        require(
            _token_value(IToken(asset).totalSupply()) >= softCap,
            "CfManagerSoftcapVesting: Invalid soft cap."
        );
    }

    //------------------------
    //  MODIFIERS
    //------------------------
    modifier ownerOnly() {
        require(
            msg.sender == state.owner,
            "CfManagerSoftcapVesting: Only owner can call this function."
        );
        _;
    }

    modifier active() {
        require(
            !state.canceled,
            "CfManagerSoftcapVesting: The campaign has been canceled."
        );
        _;
    }

    modifier finalized() {
        require(
            state.finalized,
            "CfManagerSoftcapVesting: The campaign is not finalized."
        );
        _;
    }

    modifier notFinalized() {
        require(
            !state.finalized,
            "CfManagerSoftcapVesting: The campaign is finalized."
        );
        _;
    }

    modifier isWhitelisted() {
        require(
            !state.whitelistRequired || (state.whitelistRequired && _walletApproved(msg.sender)),
            "CfManagerSoftcapVesting: Wallet not whitelisted."
        );
        _;
    }

    modifier vestingStarted() {
        require(
            state.vestingStarted,
            "CfManagerSoftcapVesting: Vesting not started"
        );
        _;
    }

    //------------------------
    // STATE CHANGE FUNCTIONS
    //------------------------
    function invest(uint256 amount) external active notFinalized isWhitelisted {
        require(amount > 0, "CfManagerSoftcapVesting: Investment amount has to be greater than 0.");

        uint256 floatingTokens = _assetERC20().balanceOf(address(this)) - state.totalClaimableTokens;
        require(floatingTokens > 0, "CfManagerSoftcapVesting: No more tokens available for sale.");

        uint256 tokens = 
            (amount / state.tokenPrice) 
                * _asset_price_precision()
                * _asset_decimals_precision() 
                / _stablecoin_decimals_precision();
        uint256 tokenValue = _token_value(tokens);
        require(tokens > 0 && tokenValue > 0, "CfManagerSoftcapVesting: Investment amount too low.");
        require(floatingTokens >= tokens, "CfManagerSoftcapVesting: Not enough tokens left for this investment amount.");        
        uint256 totalInvestmentValue = _token_value(tokens + claims[msg.sender]);
        require(
            totalInvestmentValue >= _adjusted_min_investment(floatingTokens),
            "CfManagerSoftcapVesting: Investment amount too low."
        );
        require(
            totalInvestmentValue <= state.maxInvestment,
            "CfManagerSoftcapVesting: Investment amount too high."
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
            "CfManagerSoftcapVesting: No tokens owned."
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

    function claim(address investor) external finalized vestingStarted {
        uint256 unreleased = _releasableAmount();
        require(unreleased > 0, "CfManagerSoftcapVesting: No tokens to be released.");

        state.totalClaimableTokens -= unreleased;
        claims[investor] -= unreleased;
        _assetERC20().safeTransfer(investor, unreleased);
        emit Claim(investor, state.asset, unreleased, block.timestamp);
    }

    function startVesting(
        uint256 start,
        uint256 cliffDuration,
        uint256 duration
    ) external ownerOnly finalized {
        require(!state.vestingStarted, "CfManagerSoftcapVesting: Vesting already started.");
        require(cliffDuration <= duration);
        require(duration > 0);
        require(start + duration > block.timestamp);
        state.vestingStarted = true;
        state.start = start;
        state.cliff = start + cliffDuration;
        state.duration = duration;
        emit StartVesting(
            msg.sender,
            state.asset,
            start,
            cliffDuration,
            duration,
            block.timestamp
        );
    }

    function revoke() public ownerOnly finalized vestingStarted {
        require(state.revocable, "CfManagerSoftcapVesting: Campaign vesting configuration not revocable.");
        require(!state.revoked, "CfManagerSoftcapVesting: Campaign vesting already revoked.");

        uint256 balance = state.totalClaimableTokens;
        uint256 unreleased = _totalReleasableAmount();
        uint256 refund = balance - unreleased;

        state.revoked = true;

        _assetERC20().safeTransfer(msg.sender, refund);

        emit Revoke(msg.sender, state.asset, refund, block.timestamp);
    }

    function finalize() external ownerOnly active notFinalized {
        IERC20 stablecoin = _stablecoin();
        uint256 fundsRaised = stablecoin.balanceOf(address(this));
        require(
            fundsRaised >= state.softCap,
            "CfManagerSoftcapVesting: Can only finalize campaign if the minimum funding goal has been reached."
        );
        state.finalized = true;  
        IERC20 assetERC20 = _assetERC20();
        uint256 tokensSold = state.totalTokensSold;
        uint256 tokensRefund = assetERC20.balanceOf(address(this)) - tokensSold;
        IAssetCommon(state.asset).finalizeSale();
        if (fundsRaised > 0) { stablecoin.safeTransfer(msg.sender, fundsRaised); }
        if (tokensRefund > 0) { assetERC20.safeTransfer(msg.sender, tokensRefund); }
        emit Finalize(msg.sender, state.asset, fundsRaised, tokensSold, tokensRefund, block.timestamp);
    }

    function cancelCampaign() external ownerOnly active notFinalized {
        state.canceled = true;
        uint256 tokenBalance = _assetERC20().balanceOf(address(this));
        if(tokenBalance > 0) { _assetERC20().safeTransfer(msg.sender, tokenBalance); }
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
            state.stablecoin,
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

    function getState() external view override returns (Structs.CfManagerSoftcapVestingState memory) {
        Structs.CfManagerSoftcapVestingState memory stateWithBalance = state; 
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
    function _totalReleasableAmount() private view returns (uint256) {
        uint256 vestedAmount;
        if (block.timestamp < state.cliff) {
            vestedAmount = 0;
        } else if (block.timestamp >= (state.start + state.duration) || state.revoked) {
            vestedAmount = state.totalTokensSold;
        } else {
            vestedAmount = state.totalTokensSold * (block.timestamp - state.start) / state.duration;
        }
        return vestedAmount - (state.totalTokensSold - state.totalClaimableTokens);
    }

    function _releasableAmount() private view returns (uint256) {
        return _vestedAmount() - released[msg.sender];
    }

    function _vestedAmount() private view returns (uint256) {
        if (block.timestamp < state.cliff) {
            return 0;
        } else if (block.timestamp >= (state.start + state.duration) || state.revoked) {
            return tokenAmounts[msg.sender];
        } else {
            return tokenAmounts[msg.sender] * (block.timestamp - state.start) / state.duration;
        }
    }

    function _stablecoin() private view returns (IERC20) {
        return IERC20(state.stablecoin);
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
        return 10 ** IToken(state.stablecoin).decimals();
    }

    function _token_value(uint256 tokens) private view returns (uint256) {
        return tokens
                    * state.tokenPrice
                    * _stablecoin_decimals_precision()
                    / (_asset_decimals_precision() * _asset_price_precision());
    }

    function _walletApproved(address wallet) private view returns (bool) {
        return IIssuerCommon(state.issuer).isWalletApproved(wallet);
    }

    function _adjusted_min_investment(uint256 remainingTokens) private view returns (uint256) {
        uint256 remainingTokensValue = _token_value(remainingTokens);
        return (remainingTokensValue < state.minInvestment) ? remainingTokensValue : state.minInvestment;
    }

}

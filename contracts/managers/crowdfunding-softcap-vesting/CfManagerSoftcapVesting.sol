// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./ICfManagerSoftcapVesting.sol";
import "../../tokens/erc20/IToken.sol";
import "../../shared/IAssetCommon.sol";
import "../../shared/IIssuerCommon.sol";
import "../../shared/Structs.sol";
import "../ACfManager.sol";

contract CfManagerSoftcapVesting is ICfManagerSoftcapVesting, ACfManager {
    using SafeERC20 for IERC20;

    //------------------------
    //  STATE
    //------------------------
    struct VestingState {
        bool vestingStarted;
        uint256 start;
        uint256 cliff;
        uint256 duration;
        bool revocable;
        bool revoked;
    }
    VestingState private vestingState;
    mapping (address => uint256) private released;

    //------------------------
    //  EVENTS
    //------------------------
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
    constructor(Structs.CampaignConstructor memory params) {
        require(params.owner != address(0), "CfManagerSoftcapVesting: Invalid owner address");
        require(params.asset != address(0), "CfManagerSoftcapVesting: Invalid asset address");
        require(params.tokenPrice > 0, "CfManagerSoftcapVesting: Initial price per token must be greater than 0.");
        require(
            params.maxInvestment >= params.minInvestment,
            "CfManagerSoftcapVesting: Max has to be bigger than min investment."
        );
        require(
            params.maxInvestment > 0,
            "CfManagerSoftcapVesting: Max investment has to be bigger than 0."
        );

        address fetchedIssuer = _safe_issuer_fetch(params.asset);
        address issuerProcessed = fetchedIssuer != address(0) ? fetchedIssuer : params.issuer;
        require(issuerProcessed != address(0), "CfManagerSoftcapVesting: Invalid issuer.");

        uint256 fetchedPricePrecision = _safe_price_precision_fetch(params.asset);
        uint256 pricePrecisionProcessed = fetchedPricePrecision > 0 ? fetchedPricePrecision : params.tokenPricePrecision;
        require(pricePrecisionProcessed > 0, "CfManagerSoftcapVesting: Invalid price precision.");

        address paymentMethodProcessed = params.paymentMethod == address(0) ?
            IIssuerCommon(issuerProcessed).commonState().stablecoin :
            params.paymentMethod;
        uint256 softCapNormalized = _token_value(
            _token_amount_for_investment(
                params.softCap,
                params.tokenPrice,
                params.asset,
                paymentMethodProcessed
            ),
            params.tokenPrice,
            params.asset,
            paymentMethodProcessed
        );
        uint256 minInvestmentNormalized = _token_value(
            _token_amount_for_investment(
                params.minInvestment,
                params.tokenPrice,
                params.asset,
                paymentMethodProcessed
            ),
            params.tokenPrice,
            params.asset,
            paymentMethodProcessed
        );
        state = Structs.CfManagerState(
            params.contractFlavor,
            params.contractVersion,
            address(this),
            params.owner,
            params.asset,
            issuerProcessed,
            paymentMethodProcessed,
            params.tokenPrice,
            pricePrecisionProcessed,
            softCapNormalized,
            minInvestmentNormalized,
            params.maxInvestment,
            params.whitelistRequired,
            false,
            false,
            0, 0, 0, 0, 0,
            params.info,
            params.feeManager
        );
        vestingState = VestingState(false, 0, 0, 0, true, false);
        require(
            _token_value(
                IToken(params.asset).totalSupply(),
                params.tokenPrice,
                params.asset,
                paymentMethodProcessed
            ) >= softCapNormalized,
            "CfManagerSoftcapVesting: Invalid soft cap."
        );
    }

    //------------------------
    //  MODIFIERS
    //------------------------
    modifier vestingStarted() {
        require(
            vestingState.vestingStarted,
            "CfManagerSoftcapVesting: Vesting not started"
        );
        _;
    }

    //------------------------
    // STATE CHANGE FUNCTIONS
    //------------------------
    function claim(address investor) external finalized vestingStarted {
        uint256 unreleased = _releasableAmount(investor);
        uint256 unreleasedValue = _token_value(unreleased, state.tokenPrice, state.asset, state.stablecoin);
        require(unreleased > 0, "CfManagerSoftcapVesting: No tokens to be released.");

        state.totalClaimableTokens -= unreleased;
        claims[investor] -= unreleased;
        released[investor] += unreleased;
        _assetERC20().safeTransfer(investor, unreleased);
        emit Claim(investor, state.asset, unreleased, unreleasedValue, block.timestamp);
    }

    function startVesting(
        uint256 start,
        uint256 cliffDuration,
        uint256 duration
    ) external ownerOnly finalized {
        require(!vestingState.vestingStarted, "CfManagerSoftcapVesting: Vesting already started.");
        require(cliffDuration <= duration, "CfManagerSoftcapVesting: cliffDuration <= duration");
        require(duration > 0, "CfManagerSoftcapVesting: duration > 0");
        require(start + duration > block.timestamp, "CfManagerSoftcapVesting: start + duration > block.timestamp");
        vestingState.vestingStarted = true;
        vestingState.start = start;
        vestingState.cliff = start + cliffDuration;
        vestingState.duration = duration;
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
        require(vestingState.revocable, "CfManagerSoftcapVesting: Campaign vesting configuration not revocable.");
        require(!vestingState.revoked, "CfManagerSoftcapVesting: Campaign vesting already revoked.");

        uint256 balance = state.totalClaimableTokens;
        uint256 unreleased = _totalReleasableAmount();
        uint256 refund = balance - unreleased;

        vestingState.revoked = true;

        _assetERC20().safeTransfer(msg.sender, refund);

        emit Revoke(msg.sender, state.asset, refund, block.timestamp);
    }

    //------------------------
    //  ICfManagerSoftcap IMPL
    //------------------------
    function getState() external view override returns (Structs.CfManagerSoftcapVestingState memory) {
        return Structs.CfManagerSoftcapVestingState(
            state.flavor,
            state.version,
            state.contractAddress,
            state.owner,
            state.asset,
            state.issuer,
            state.stablecoin,
            state.tokenPrice,
            state.softCap,
            state.minInvestment,
            state.maxInvestment,
            state.whitelistRequired,
            state.finalized,
            state.canceled,
            state.totalClaimableTokens,
            state.totalInvestorsCount,
            state.totalFundsRaised,
            state.totalTokensSold,
            _assetERC20().balanceOf(address(this)),
            state.info,
            vestingState.vestingStarted,
            vestingState.start,
            vestingState.cliff,
            vestingState.duration,
            vestingState.revocable,
            vestingState.revoked,
            state.feeManager
        );
    }

    //------------------------
    //  HELPERS
    //------------------------
    function _totalReleasableAmount() private view returns (uint256) {
        uint256 vestedAmount;
        if (block.timestamp < vestingState.cliff) {
            vestedAmount = 0;
        } else if (block.timestamp >= (vestingState.start + vestingState.duration) || vestingState.revoked) {
            vestedAmount = state.totalTokensSold;
        } else {
            vestedAmount = state.totalTokensSold * (block.timestamp - vestingState.start) / vestingState.duration;
        }
        return vestedAmount - (state.totalTokensSold - state.totalClaimableTokens);
    }

    function _releasableAmount(address investor) private view returns (uint256) {
        return _vestedAmount(investor) - released[investor];
    }

    function _vestedAmount(address investor) private view returns (uint256) {
        if (block.timestamp < vestingState.cliff) {
            return 0;
        } else if (block.timestamp >= (vestingState.start + vestingState.duration) || vestingState.revoked) {
            return tokenAmounts[investor];
        } else {
            return tokenAmounts[investor] * (block.timestamp - vestingState.start) / vestingState.duration;
        }
    }

}

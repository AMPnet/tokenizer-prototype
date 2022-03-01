// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../crowdfunding-softcap/ICfManagerSoftcap.sol";
import "../../tokens/erc20/IToken.sol";
import "../../shared/IAssetCommon.sol";
import "../../shared/IIssuerCommon.sol";
import "../../shared/Structs.sol";
import "../ACfManager.sol";

contract CfManagerSoftcap is ICfManagerSoftcap, ACfManager {
    using SafeERC20 for IERC20;

    //------------------------
    //  STATE
    //------------------------
    uint256 private totalClaimsCount = 0;

    //------------------------
    //  CONSTRUCTOR
    //------------------------
    constructor(Structs.CampaignConstructor memory params) {
        require(params.owner != address(0), "CfManagerSoftcap: Invalid owner address");
        require(params.asset != address(0), "CfManagerSoftcap: Invalid asset address");
        require(params.tokenPrice > 0, "CfManagerSoftcap: Initial price per token must be greater than 0.");
        require(
            params.maxInvestment >= params.minInvestment,
            "CfManagerSoftcap: Max has to be bigger than min investment."
        );
        require(params.maxInvestment > 0, "CfManagerSoftcap: Max investment has to be bigger than 0.");
        
        address fetchedIssuer = _safe_issuer_fetch(params.asset);
        address issuerProcessed = fetchedIssuer != address(0) ? fetchedIssuer : params.issuer;
        require(issuerProcessed != address(0), "CfManagerSoftcap: Invalid issuer.");

        address paymentMethodProcessed = params.paymentMethod == address(0) ?
            IIssuerCommon(issuerProcessed).commonState().stablecoin :
            params.paymentMethod;
        uint256 softCapNormalized = _token_value(
            _token_amount_for_investment(
                params.softCap,
                params.tokenPrice,
                params.tokenPriceDecimals,
                params.asset,
                paymentMethodProcessed
            ),
            params.tokenPrice,
            params.tokenPriceDecimals,
            params.asset,
            paymentMethodProcessed
        );
        uint256 minInvestmentNormalized = _token_value(
            _token_amount_for_investment(
                params.minInvestment,
                params.tokenPrice,
                params.tokenPriceDecimals,
                params.asset,
                paymentMethodProcessed
            ),
            params.tokenPrice,
            params.tokenPriceDecimals,
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
            params.tokenPriceDecimals,
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
        require(
            _token_value(
                IToken(params.asset).totalSupply(),
                params.tokenPrice,
                params.tokenPriceDecimals,
                params.asset,
                paymentMethodProcessed
            ) >= softCapNormalized,
            "CfManagerSoftcap: Invalid soft cap."
        );
    }

    //------------------------
    // STATE CHANGE FUNCTIONS
    //------------------------
    function claim(address investor) external finalized {
        uint256 claimableTokens = claims[investor];
        uint256 claimableTokensValue = investments[investor];
        require(
            claimableTokens > 0 && claimableTokensValue > 0,
            "CfManagerSoftcap: No tokens owned."
        );
        totalClaimsCount += 1;
        state.totalClaimableTokens -= claimableTokens;
        claims[investor] = 0;
        _assetERC20().safeTransfer(investor, claimableTokens);
        emit Claim(investor, state.asset, claimableTokens, claimableTokensValue, block.timestamp);
    }

    //------------------------
    //  ICfManagerSoftcap IMPL
    //------------------------
    function getState() external view override returns (Structs.CfManagerSoftcapState memory) {
        return Structs.CfManagerSoftcapState(
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
            totalClaimsCount,
            state.totalFundsRaised,
            state.totalTokensSold,
            _assetERC20().balanceOf(address(this)),
            state.info,
            state.feeManager
        );
    }
}

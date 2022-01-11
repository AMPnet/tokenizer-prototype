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
        string memory info,
        address feeManager
    ) {
        require(owner != address(0), "CfManagerSoftcap: Invalid owner address");
        require(asset != address(0), "CfManagerSoftcap: Invalid asset address");
        require(tokenPrice > 0, "CfManagerSoftcap: Initial price per token must be greater than 0.");
        require(maxInvestment >= minInvestment, "CfManagerSoftcap: Max has to be bigger than min investment.");
        require(maxInvestment > 0, "CfManagerSoftcap: Max investment has to be bigger than 0.");
        uint256 softCapNormalized = _token_value(
            _token_amount_for_investment(softCap, tokenPrice, asset),
            tokenPrice,
            asset
        );
        uint256 minInvestmentNormalized = _token_value(
            _token_amount_for_investment(minInvestment, tokenPrice, asset),
            tokenPrice,
            asset
        );
        IIssuerCommon issuer = IIssuerCommon(IAssetCommon(asset).commonState().issuer);
        state = Structs.CfManagerState(
            contractFlavor,
            contractVersion,
            address(this),
            owner,
            asset,
            address(issuer),
            issuer.commonState().stablecoin,
            tokenPrice,
            softCapNormalized,
            minInvestmentNormalized,
            maxInvestment,
            whitelistRequired,
            false,
            false,
            0, 0, 0, 0, 0,
            info,
            feeManager
        );
        require(
            _token_value(IToken(asset).totalSupply(), tokenPrice, asset) >= softCapNormalized,
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

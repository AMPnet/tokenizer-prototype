// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./IMirroredToken.sol";
import "../asset/IAsset.sol";
import "../issuer/IIssuer.sol";
import "../shared/Structs.sol";
import "../tokens/erc20/ERC20.sol";
import "../tokens/erc20/ERC20Snapshot.sol";

contract MirroredToken is IMirroredToken, ERC20Snapshot {
    using SafeERC20 for IERC20;

    //------------------------
    //  STATE
    //------------------------
    IAsset public originalToken;
    address public priceProvider;
    bool public liquidated;
    uint256 public liquidationFundsTotal;
    uint256 public liquidationTimestamp;
    uint256 public liquidationFundsClaimed;
    Structs.TokenPriceRecord public tokenPriceRecord;
    mapping (address => uint256) public liquidationClaimsMap;

    //------------------------
    //  EVENTS
    //------------------------
    event MintMirrored(address indexed wallet, uint256 amount, address originalToken, uint256 timestamp);
    event BurnMirrored(address indexed wallet, uint256 amount, address originalToken, uint256 timestamp);
    event UpdateTokenPrice(address caller, uint256 price, uint256 expiry, uint256 timestamp);
    event Liquidated(
        address originalAsset,
        uint256 liquidatedTokensAmount,
        uint256 liqudationFunds,
        uint256 timestamp
    );
    event ClaimLiquidationShare(address investor, address originalAsset, uint256 amount, uint256 timestamp);

    //------------------------
    //  CONSTRUCTOR
    //------------------------
    constructor(
        string memory _name,
        string memory _symbol,
        address _priceProvider,
        IAsset _originalToken,
        address _childChainManager
    ) ERC20(_name, _symbol) {
        require(address(_originalToken) != address(0), "MirroredToken: invalid original token address");
        require(_priceProvider != address(0), "MirroredToken: invalid price provider address");
        require(
            IToken(address(_originalToken)).decimals() == decimals(),
            "MirroredToken: original and mirrored asset decimal precision mismatch"
        );
        require(_childChainManager != address(0), "MirroredToken: invalid child chain manager address");
        originalToken = _originalToken;
        priceProvider = _priceProvider;
    }

    //------------------------
    //  MODIFIERS
    //------------------------
    modifier notLiquidated() {
        require(!liquidated, "MirroredToken: Action forbidden, asset liquidated.");
        _;
    }

    //------------------------------
    //  IMirroredToken IMPL - Write
    //------------------------------
    function mintMirrored(address wallet, uint256 amount) external override notLiquidated {
        require(msg.sender == address(originalToken), "MirroredToken: Only original token can mint.");
        _mint(wallet, amount);
        emit MintMirrored(wallet, amount, msg.sender, block.timestamp);
    }

    function burnMirrored(uint256 amount) external override notLiquidated {
        _burn(msg.sender, amount);
        originalToken.unlockTokens(msg.sender, amount);
        emit BurnMirrored(msg.sender, amount, address(originalToken), block.timestamp);
    }

    function updateTokenPrice(uint256 price, uint256 expiry) external override notLiquidated {
        // This number should be provided by the trusted party
        // APX protocol will handle liquidation requests and provide the price/value of the mirrored tokens
        // We can implement arbitrary logic here, to revert liquidation if price/value is not known or the
        // provided price was outdated.
        require(
            msg.sender == priceProvider,
            "MirroredToken: not allowed;"
        );
        require(
            price > 0,
            "MirroredToken: price has to be > 0;"
        );
        tokenPriceRecord = Structs.TokenPriceRecord(
            price,
            block.timestamp,
            block.timestamp + expiry,
            totalSupply(),
            msg.sender
        );
        emit UpdateTokenPrice(msg.sender, price, expiry, block.timestamp);
    }

    function liquidate() external override notLiquidated returns (uint256) {
        require(
            msg.sender == address(originalToken),
            "MirroredToken: not allowed; caller must be an original asset address"
        );
        require(
            block.timestamp <= tokenPriceRecord.validUntilTimestamp,
            "MirroredToken: price expired; update price before trying to liquidate"
        );
        require(
            totalSupply() == tokenPriceRecord.capturedSupply,
            "MirroredToken: total supply was changed since the last price update; update price again"
        );
        uint256 liquidationTokenAmount = totalSupply();
        uint256 liquidationFunds = _tokenValue(liquidationTokenAmount);
        require(
            _stablecoin().balanceOf(address(this)) >= liquidationFunds,
            "MirroredToken: not enough funds for liquidation; transfer funds before liquidation"
        );
        liquidated = true;
        liquidationTimestamp = block.timestamp;
        liquidationFundsTotal = liquidationFunds;
        emit Liquidated(msg.sender, totalSupply(), liquidationFundsTotal, block.timestamp);
        return liquidationTokenAmount;
    }

    function claimLiquidationShare(address investor) external override {
        require(liquidated, "MirroredToken: not liquidated");
        require(
            !originalToken.getState().whitelistRequiredForLiquidationClaim ||
            _issuer().isWalletApproved(investor),
            "MirroredToken: wallet must be whitelisted before claiming liquidation share."
        );
        uint256 approvedAmount = allowance(investor, address(this));
        require(approvedAmount > 0, "MirroredToken: no tokens approved for claiming liquidation share");
        uint256 liquidationFundsShare = approvedAmount * liquidationFundsTotal / totalSupply();
        require(liquidationFundsShare > 0, "MirroredToken: no liquidation funds to claim");
        _stablecoin().safeTransfer(investor, liquidationFundsShare);
        transferFrom(investor, address(this), approvedAmount);
        liquidationClaimsMap[investor] += liquidationFundsShare;
        liquidationFundsClaimed += liquidationFundsShare;
        emit ClaimLiquidationShare(investor, address(originalToken), liquidationFundsShare, block.timestamp);
    }

    //------------------------------
    //  IMirroredToken IMPL - Read
    //------------------------------
    function lastKnownMarketCap() external view override returns (uint256) {
        return _tokenValue(totalSupply());
    }

    //------------------------
    //  HELPERS
    //------------------------
    function _tokenValue(uint256 tokenAmount) private view returns (uint256) {
        return tokenAmount
                    * tokenPriceRecord.price
                    * _stablecoin_decimals_precision()
                    / (IToken(address(originalToken)).decimals() * originalToken.priceDecimalsPrecision());
    }

    function _originalAssetDecimalsPrecision() private view returns (uint256) {
        return 10 ** IToken(address(originalToken)).decimals();
    }

    function _stablecoin_decimals_precision() private view returns (uint256) {
        return 10 ** IToken(_issuer().getState().stablecoin).decimals();
    }

    function _stablecoin() private view returns (IERC20) {
        return IERC20(_issuer().getState().stablecoin);
    }

    function _issuer() private view returns (IIssuer) {
        return IIssuer(originalToken.getState().issuer);
    }

}

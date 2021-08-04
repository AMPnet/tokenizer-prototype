// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Snapshot.sol";
import "./IMirroredToken.sol";
import "../asset/IAsset.sol";
import "../issuer/IIssuer.sol";

contract MirroredToken is ERC20Snapshot, IMirroredToken {
    using SafeERC20 for IERC20;
    
    struct TokenPriceRecord {
        uint256 price;
        uint256 updatedAtTimestamp;
        uint256 validUntilTimestamp;
        address provider;
    }

    //------------------------
    //  CONSTANTS
    //------------------------
    uint256 constant PRICE_DECIMALS_PRECISION = 10 ** 4;
    uint256 constant STABLECOIN_DECIMALS_PRECISION = 10 ** 18;

    //------------------------
    //  STATE
    //------------------------
    IAsset public originalToken;
    address public priceProvider;
    bool public liquidated;
    uint256 public liquidationTimestamp;
    uint256 public liquidationSnapshotId;
    uint256 public liquidationFundsClaimed;
    TokenPriceRecord public tokenPriceRecord;
    mapping (address => uint256) public liquidationClaimsMap;

    //------------------------
    //  EVENTS
    //------------------------
    event ConvertFromOriginal(address caller, address mirroredToken, uint256 amount, uint256 timestamp);
    event UpdateTokenPrice(address caller, uint256 price, uint256 expiry, uint256 timestamp);
    event Liquidated(address originalAsset, uint256 liqudationFunds, uint256 liquidationSnapshotId, uint256 timestamp);
    event ClaimLiquidationShare(address investor, address originalAsset, uint256 amount, uint256 timestamp);

    //------------------------
    //  CONSTRUCTOR
    //------------------------
    constructor(
        string memory _name,
        string memory _symbol,
        address _priceProvider,
        IAsset _originalToken
    ) ERC20(_name, _symbol) {
        require(
            address(_originalToken) != address(0),
            "MirroredToken: invalid original token address"
        );
        require(
            _priceProvider != address(0),
            "MirroredToken: invalid price provider address"
        );
        require(
            _originalToken.getDecimals() == decimals(),
            "MirroredToken: original and mirrored asset decimal precision mismatch"
        );
        originalToken = _originalToken;
        priceProvider = _priceProvider;
        _mint(address(this), originalToken.totalShares());
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
    function convertFromOriginal() external override notLiquidated {
        require(
            address(originalToken) != address(0),
            "MirroredToken: can't convert from original token; Original token was never initialized."
        );
        IERC20 originalTokenERC20 = IERC20(address(originalToken));
        uint256 amount = originalTokenERC20.allowance(msg.sender, address(this));
        require(
            amount > 0,
            "MirroredToken: can't convert from original token; Missing approval."
        );
        originalTokenERC20.safeTransferFrom(msg.sender, address(this), amount);
        transfer(msg.sender, amount);
        emit ConvertFromOriginal(msg.sender, address(originalToken), amount, block.timestamp);
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
        tokenPriceRecord = TokenPriceRecord(
            price,
            block.timestamp,
            block.timestamp + expiry,
            msg.sender
        );
        emit UpdateTokenPrice(msg.sender, price, expiry, block.timestamp);
    }

    function liquidate() external override notLiquidated {
        require(
            msg.sender == address(originalToken),
            "MirroredToken: not allowed; caller must be an original asset address"
        );
        require(
            block.timestamp <= tokenPriceRecord.validUntilTimestamp,
            "MirroredToken: price expired; update price before trying to liquidate"
        );
        uint256 liquidationFunds = _tokenValue(_circulatingSupply());
        require(
            _stablecoin().balanceOf(address(this)) >= liquidationFunds,
            "MirroredToken: not enough funds for liquidation; transfer funds before liquidation"
        );
        uint256 snapshotId = _snapshot();
        liquidated = true;
        liquidationTimestamp = block.timestamp;
        liquidationSnapshotId = snapshotId;
        emit Liquidated(msg.sender, liquidationFunds, liquidationSnapshotId, block.timestamp);
    }

    function claimLiquidationShare(address investor) external override {
        require(
            liquidated, "MirroredToken: not liquidated"
        );
        require(
            liquidationClaimsMap[investor] == 0,
            "MirroredToken: investor has already claimed liquidation funds"
        );
        uint256 amount = _tokenValue(balanceOfAt(investor, liquidationSnapshotId));
        _stablecoin().transfer(investor, amount);
        liquidationClaimsMap[investor] = amount;
        emit ClaimLiquidationShare(investor, address(originalToken), amount, block.timestamp);
    }

    //------------------------------
    //  IMirroredToken IMPL - Read
    //------------------------------
    function circulatingSupply() external view override returns (uint256) {
        return totalSupply() - balanceOf(address(this));  
    }

    function lastKnownTokenValue() external view override returns (uint256) {
        return _tokenValue(_circulatingSupply());
    }

    //------------------------
    //  HELPERS
    //------------------------
    function _tokenValue(uint256 tokenAmount) private view returns (uint256) {
        return tokenAmount
                    * tokenPriceRecord.price
                    * STABLECOIN_DECIMALS_PRECISION
                    / (originalToken.getDecimals() * PRICE_DECIMALS_PRECISION);
    }

    function _circulatingSupply() private view returns (uint256) {
        return totalSupply() - balanceOf(address(this));
    }

    function _stablecoin() private view returns (IERC20) {
        return IERC20(IIssuer(originalToken.getState().issuer).getState().stablecoin);
    }

    function _originalAssetDecimalsPrecision() private view returns (uint256) {
        return 10 ** originalToken.getDecimals();
    }

}

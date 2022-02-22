// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./IMirroredToken.sol";
import "../asset/IAsset.sol";
import "../shared/Structs.sol";
import "../tokens/erc20/ERC20.sol";

contract MirroredToken is IMirroredToken, ERC20 {
    using SafeERC20 for IERC20;

    string constant public FLAVOR = "MirroredTokenV1";
    string constant public VERSION = "1.0.30";

    //------------------------
    //  STATE
    //------------------------
    IAsset public originalToken;

    //------------------------
    //  EVENTS
    //------------------------
    event MintMirrored(address indexed wallet, address asset, uint256 amount, address originalToken, uint256 timestamp);
    event BurnMirrored(address indexed wallet, address asset, uint256 amount, address originalToken, uint256 timestamp);


    //------------------------
    //  CONSTRUCTOR
    //------------------------
    constructor(
        string memory _name,
        string memory _symbol,
        IAsset _originalToken
    ) ERC20(_name, _symbol) {
        require(address(_originalToken) != address(0), "MirroredToken: invalid original token address");
        require(
            IToken(address(_originalToken)).decimals() == decimals(),
            "MirroredToken: original and mirrored asset decimal precision mismatch"
        );
        originalToken = _originalToken;
    }

    //------------------------------
    //  IMirroredToken IMPL
    //------------------------------
    function mintMirrored(address wallet, uint256 amount) external override {
        require(msg.sender == address(originalToken), "MirroredToken: Only original token can mint.");
        _mint(wallet, amount);
        emit MintMirrored(wallet, address(originalToken), amount, msg.sender, block.timestamp);
    }

    function burnMirrored(uint256 amount) external override {
        _burn(msg.sender, amount);
        originalToken.unlockTokens(msg.sender, amount);
        emit BurnMirrored(msg.sender, address(originalToken), amount, address(originalToken), block.timestamp);
    }
    
    function flavor() external pure override returns (string memory) { return FLAVOR; }
    
    function version() external pure override returns (string memory) { return VERSION; }

}

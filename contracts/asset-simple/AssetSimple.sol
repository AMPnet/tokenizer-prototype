// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./IAssetSimple.sol";
import "../shared/IAssetCommon.sol";
import "../shared/Structs.sol";
import "../shared/IIssuerCommon.sol";
import "../shared/ICampaignCommon.sol";

contract AssetSimple is IAssetSimple, ERC20 {

    //------------------------
    //  CONSTANTS
    //------------------------
    uint256 constant public override priceDecimalsPrecision = 10 ** 4;

    //-----------------------
    //  STATE
    //-----------------------
    Structs.AssetSimpleState private state;
    Structs.InfoEntry[] private infoHistory;
    Structs.TokenSaleInfo[] private sellHistory;
    mapping (address => Structs.WalletRecord) public approvedCampaignsMap;
    mapping (address => Structs.TokenSaleInfo) public successfulTokenSalesMap;

    //------------------------
    //  EVENTS
    //------------------------
    event SetInfo(string info, address setter, uint256 timestamp);
    event FinalizeSale(address campaign, uint256 tokenAmount, uint256 tokenValue, uint256 timestamp);

    //------------------------
    //  CONSTRUCTOR
    //------------------------
    constructor(Structs.AssetSimpleConstructorParams memory params) ERC20(params.name, params.symbol) {
        require(params.owner != address(0), "AssetSimple: Invalid owner provided");
        require(params.issuer != address(0), "AssetSimple: Invalid issuer provided");
        require(params.initialTokenSupply > 0, "AssetSimple: Initial token supply can't be 0");
        infoHistory.push(Structs.InfoEntry(
            params.info,
            block.timestamp
        ));
        bool assetApprovedByIssuer = (IIssuerCommon(params.issuer).commonState().owner == params.owner);
        address contractAddress = address(this);
        state = Structs.AssetSimpleState(
            params.flavor,
            params.version,
            contractAddress,
            params.owner,
            params.info,
            params.name,
            params.symbol,
            params.initialTokenSupply,
            decimals(),
            params.issuer,
            assetApprovedByIssuer,
            0, 0
        );
        _mint(params.owner, params.initialTokenSupply);
    }

    //------------------------
    //  MODIFIERS
    //------------------------
    modifier ownerOnly() {
        require(
            msg.sender == state.owner,
            "AssetSimple: Only asset creator can make this action."
        );
        _;
    }

    //------------------------
    //  IMPLEMENTATION
    //------------------------
    function flavor() external view override returns (string memory) { return state.flavor; }
    
    function version() external view override returns (string memory) { return state.version; }

    function changeOwnership(address newOwner) external override ownerOnly {
        state.owner = newOwner;
        if (newOwner == IIssuerCommon(state.issuer).commonState().owner) { state.assetApprovedByIssuer = true; }
    }

    function setCampaignState(address campaign, bool approved) external override ownerOnly {
        bool campaignExists = approvedCampaignsMap[campaign].wallet == campaign;
        if (campaignExists) {
            approvedCampaignsMap[campaign].whitelisted = approved;
        } else {
            approvedCampaignsMap[campaign] = Structs.WalletRecord(campaign, approved);
        }
    }

    function setIssuerStatus(bool status) external override {
        require(
            msg.sender == IIssuerCommon(state.issuer).commonState().owner,
            "AssetSimple: Only issuer owner can make this action." 
        );
        state.assetApprovedByIssuer = status;
    }

    function setInfo(string memory info) external override {
        infoHistory.push(Structs.InfoEntry(
            info,
            block.timestamp
        ));
        state.info = info;
        emit SetInfo(info, msg.sender, block.timestamp);
    }

    function finalizeSale() external override {
        address campaign = msg.sender;
        require(_campaignWhitelisted(campaign), "AssetSimple: Campaign not approved.");
        Structs.CampaignCommonState memory campaignState = ICampaignCommon(campaign).commonState();
        require(campaignState.finalized, "AssetSimple: Campaign not finalized");
        uint256 tokenValue = campaignState.fundsRaised;
        uint256 tokenAmount = campaignState.tokensSold;
        require(
            tokenAmount > 0 && balanceOf(campaign) >= tokenAmount,
            "AssetSimple: Campaign has signalled the sale finalization but campaign tokens are not present"
        );
        require(
            tokenValue > 0 && IERC20(campaignState.stablecoin).balanceOf(campaign) >= tokenValue,
            "AssetSimple: Campaign has signalled the sale finalization but raised funds are not present"
        );
        state.totalAmountRaised += tokenValue;
        state.totalTokensSold += tokenAmount;
        Structs.TokenSaleInfo memory tokenSaleInfo = Structs.TokenSaleInfo(
            campaign, tokenAmount, tokenValue, block.timestamp
        );
        sellHistory.push(tokenSaleInfo);
        successfulTokenSalesMap[campaign] = tokenSaleInfo;
        emit FinalizeSale(
            msg.sender,
            tokenAmount,
            tokenValue,
            block.timestamp
        );
    }

    function getState() external view override returns (Structs.AssetSimpleState memory) {
        return state;
    }

    function getInfoHistory() external view override returns (Structs.InfoEntry[] memory) {
        return infoHistory;
    }

    function getSellHistory() external view override returns (Structs.TokenSaleInfo[] memory) {
        return sellHistory;
    }
    
    function commonState() external view override returns (Structs.AssetCommonState memory) { 
        return Structs.AssetCommonState(
            state.flavor,
            state.version,
            state.contractAddress,
            state.owner,
            state.info,
            state.name,
            state.symbol,
            totalSupply(),
            decimals(),
            state.issuer
        );
    }

    //---------------
    //  HELPERS
    //---------------
    function _campaignWhitelisted(address campaignAddress) private view returns (bool) {
        if (ICampaignCommon(campaignAddress).commonState().owner == state.owner) {
            return true;
        }
        Structs.WalletRecord memory campaignRecord = approvedCampaignsMap[campaignAddress];
        return (campaignRecord.wallet == campaignAddress && campaignRecord.whitelisted);
    }

}

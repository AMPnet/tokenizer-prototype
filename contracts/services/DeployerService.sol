// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../asset/IAsset.sol";
import "../asset/IAssetFactory.sol";
import "../issuer/IIssuer.sol";
import "../issuer/IIssuerFactory.sol";
import "../managers/crowdfunding-softcap/ICfManagerSoftcapFactory.sol";

contract DeployerService {

    struct DeployIssuerAssetCampaignRequest {
        IIssuerFactory issuerFactory;
        IAssetFactory assetFactory;
        ICfManagerSoftcapFactory cfManagerSoftcapFactory;
        address issuerOwner;
        address issuerStablecoin;
        address issuerWalletApprover;
        string issuerInfo;
        address assetOwner;
        uint256 assetInitialTokenSupply;
        bool assetWhitelistRequired;
        string assetName;
        string assetSymbol;
        string assetInfo;
        address cfManagerOwner;
        uint256 cfManagerPricePerToken;
        uint256 cfManagerSoftcap;
        uint256 cfManagerTokensToSellAmount;
        bool cfManagerWhitelistRequired;
        string cfManagerInfo;
    }

    function deployIssuerAssetCampaign(DeployIssuerAssetCampaignRequest memory request) external {
        IIssuer issuer = IIssuer(request.issuerFactory.create(
            address(this),
            request.issuerStablecoin,
            request.issuerWalletApprover,
            request.issuerInfo
        ));
        IAsset asset = IAsset(request.assetFactory.create(
            address(this),
            address(issuer),
            request.assetInitialTokenSupply,
            request.assetWhitelistRequired,
            request.assetName,
            request.assetSymbol,
            request.assetInfo
        ));
        address campaign = request.cfManagerSoftcapFactory.create(
            address(this),
            address(asset),
            request.cfManagerPricePerToken,
            request.cfManagerSoftcap,
            request.cfManagerWhitelistRequired,
            request.cfManagerInfo
        );
        asset.approveCampaign(campaign);
        uint256 tokensToSell = request.cfManagerTokensToSellAmount;
        uint256 tokensToKeep = asset.totalShares() - tokensToSell;
        IERC20 assetERC20 = IERC20(address(asset));
        assetERC20.transfer(campaign, tokensToSell);
        assetERC20.transfer(request.assetOwner, tokensToKeep);
        issuer.changeOwnership(request.issuerOwner);

    }

    function deployAssetCampaign() external {

    }

    function deployCampaign() external {

    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../asset/IAsset.sol";
import "../asset/IAssetFactory.sol";
import "../issuer/IIssuer.sol";
import "../issuer/IIssuerFactory.sol";
import "../managers/crowdfunding-softcap/ICfManagerSoftcap.sol";
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
        // Deploy contracts
        IIssuer issuer = IIssuer(request.issuerFactory.create(
            address(this),
            request.issuerStablecoin,
            address(this),
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
        ICfManagerSoftcap campaign = ICfManagerSoftcap(request.cfManagerSoftcapFactory.create(
            address(this),
            address(asset),
            request.cfManagerPricePerToken,
            request.cfManagerSoftcap,
            request.cfManagerWhitelistRequired,
            request.cfManagerInfo
        ));

        // Approve owners and campaign
        issuer.approveWallet(request.issuerOwner);
        issuer.approveWallet(request.assetOwner);
        issuer.approveWallet(request.cfManagerOwner);
        asset.approveCampaign(address(campaign));
        asset.setIssuerStatus(true);
        
        // Transfer tokens to sell to the campaign, transfer the rest to the asset owner's wallet
        uint256 tokensToSell = request.cfManagerTokensToSellAmount;
        uint256 tokensToKeep = asset.totalShares() - tokensToSell;
        IERC20 assetERC20 = IERC20(address(asset));
        assetERC20.transfer(address(campaign), tokensToSell);
        assetERC20.transfer(request.assetOwner, tokensToKeep);
        
        // Transfer ownerships from address(this) to the actual owner wallets
        issuer.changeWalletApprover(request.issuerWalletApprover);
        issuer.changeOwnership(request.issuerOwner);
        asset.changeOwnership(request.assetOwner);
        campaign.changeOwnership(request.cfManagerOwner);
    }

    function deployAssetCampaign() external {
        // TODO: Implement
    }

    function deployCampaign() external {
        // TODO: Implement
    }

}

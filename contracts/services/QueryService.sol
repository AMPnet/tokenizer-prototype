 // SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../shared/Structs.sol";
import "../shared/ICampaignFactoryCommon.sol";
import "../shared/IAssetFactoryCommon.sol";
import "../shared/IIssuerFactoryCommon.sol";
import "../shared/ICampaignCommon.sol";
import "../shared/IAssetCommon.sol";
import "../shared/IIssuerCommon.sol";
import "../shared/IVersioned.sol";
import "../registry/INameRegistry.sol";
import "../tokens/erc20/IToken.sol";

interface IQueryService is IVersioned {
    function getIssuers(
        address[] memory factories,
        INameRegistry nameRegistry
    ) external view returns (Structs.IssuerCommonStateWithName[] memory);

    function getIssuerForName(
        string memory issuerName,
        INameRegistry nameRegistry
    ) external view returns (Structs.IssuerCommonStateWithName memory);

    function getIssuer(
        address issuer,
        INameRegistry nameRegistry
    ) external view returns (Structs.IssuerCommonStateWithName memory);

    function getAssetForName(
        string memory assetName,
        INameRegistry nameRegistry
    ) external view returns (Structs.AssetCommonStateWithName memory);

    function getAsset(
        address asset,
        INameRegistry nameRegistry
    ) external view returns (Structs.AssetCommonStateWithName memory);

    function getCampaignForName(
        string memory campaignName,
        INameRegistry nameRegistry
    ) external view returns (Structs.CampaignCommonStateWithName memory);

    function getCampaign(
        address campaign,
        INameRegistry nameRegistry
    ) external view returns (Structs.CampaignCommonStateWithName memory);

    function getCampaignsForIssuerName(
        string memory issuerName,
        address[] memory factories,
        INameRegistry nameRegistry
    ) external view returns (Structs.CampaignCommonStateWithName[] memory);

    function getCampaignsForIssuer(
        address issuer,
        address[] memory factories,
        INameRegistry nameRegistry
    ) external view returns (Structs.CampaignCommonStateWithName[] memory);

    function getCampaignForIssuerNameInvestor(
        string memory issuerName,
        address investor,
        address[] memory factories,
        INameRegistry nameRegistry
    ) external view returns (Structs.CampaignCommonStateWithNameAndInvestment[] memory);

    function getCampaignsForIssuerInvestor(
        address issuer,
        address investor,
        address[] memory factories,
        INameRegistry nameRegistry
    ) external view returns (Structs.CampaignCommonStateWithNameAndInvestment[] memory);

    function getCampaignsForAssetName(
        string memory assetName,
        address[] memory factories,
        INameRegistry nameRegistry
    ) external view returns (Structs.CampaignCommonStateWithName[] memory);

    function getCampaignsForAsset(
        address asset,
        address[] memory factories,
        INameRegistry nameRegistry
    ) external view returns (Structs.CampaignCommonStateWithName[] memory);

    function getCampaignsForAssetNameInvestor(
        string memory assetName,
        address investor,
        address[] memory factories,
        INameRegistry nameRegistry
    ) external view returns (Structs.CampaignCommonStateWithNameAndInvestment[] memory);
    
    function getCampaignsForAssetInvestor(
        address asset,
        address investor,
        address[] memory factories,
        INameRegistry nameRegistry
    ) external view returns (Structs.CampaignCommonStateWithNameAndInvestment[] memory);

    function getAssetsForIssuerName(
        string memory issuerName,
        address[] memory factories,
        INameRegistry nameRegistry
    ) external view returns (Structs.AssetCommonStateWithName[] memory);

    function getAssetsForIssuer(
        address issuer,
        address[] memory factories,
        INameRegistry nameRegistry
    ) external view returns (Structs.AssetCommonStateWithName[] memory);

    function getERC20AssetsForIssuer(
        address issuer,
        address[] memory assetFactories,
        address[] memory campaignFactories
    ) external view returns (Structs.ERC20AssetCommonState[] memory);
    
    function getAssetBalancesForIssuer(
        address issuer,
        address investor,
        address[] memory assetFactories,
        address[] memory campaignFactories
    ) external view returns (Structs.AssetBalance[] memory);

}

contract QueryService is IQueryService {

    string constant public FLAVOR = "QueryServiceV1";
    string constant public VERSION = "1.0.31";

    function flavor() external pure override returns (string memory) { return FLAVOR; }
    function version() external pure override returns (string memory) { return VERSION; } 

    function getIssuers(
        address[] memory factories,
        INameRegistry nameRegistry
    ) public view override returns (Structs.IssuerCommonStateWithName[] memory) {
        if (factories.length == 0) { return new Structs.IssuerCommonStateWithName[](0); }
        
        uint256 totalItems = 0;
        uint256[] memory instanceCountPerFactory = new uint256[](factories.length);
        for (uint256 i = 0; i < factories.length; i++) {
            uint256 count = IIssuerFactoryCommon(factories[i]).getInstances().length;
            totalItems += count;
            instanceCountPerFactory[i] = count;
        }
        if (totalItems == 0) { return new Structs.IssuerCommonStateWithName[](0); }
        
        Structs.IssuerCommonStateWithName[] memory response = new Structs.IssuerCommonStateWithName[](totalItems);
        uint256 position = 0;
        for (uint256 i = 0; i < factories.length; i++) {
            if (instanceCountPerFactory[i] == 0) continue;
            address[] memory instances = IIssuerFactoryCommon(factories[i]).getInstances();
            for (uint256 j = 0; j < instanceCountPerFactory[i]; j++) {
                IIssuerCommon issuerInterface = IIssuerCommon(instances[j]);
                response[position] = Structs.IssuerCommonStateWithName(
                    issuerInterface.commonState(),
                    nameRegistry.getIssuerName(instances[j])
                );
                position++;
            }
        }

        return response;
    }

    function getIssuerForName(
        string memory issuerName,
        INameRegistry nameRegistry
    ) public view override returns (Structs.IssuerCommonStateWithName memory) {
        address issuer = nameRegistry.getIssuer(issuerName);
        return getIssuer(issuer, nameRegistry);
    }

    function getIssuer(
        address issuer,
        INameRegistry nameRegistry
    ) public view override returns (Structs.IssuerCommonStateWithName memory) {
        return Structs.IssuerCommonStateWithName(
            IIssuerCommon(issuer).commonState(),
            nameRegistry.getIssuerName(issuer)
        );
    }

    function getAssetForName(
        string memory assetName,
        INameRegistry nameRegistry
    ) public view override returns (Structs.AssetCommonStateWithName memory) {
        address asset = nameRegistry.getAsset(assetName);
        return getAsset(asset, nameRegistry);
    }

    function getAsset(
        address asset,
        INameRegistry nameRegistry
    ) public view override returns (Structs.AssetCommonStateWithName memory) {
        return Structs.AssetCommonStateWithName(
            IAssetCommon(asset).commonState(),
            nameRegistry.getAssetName(asset)
        );
    }

    function getCampaignForName(
        string memory campaignName,
        INameRegistry nameRegistry
    ) public view override returns (Structs.CampaignCommonStateWithName memory) {
        address campaign = nameRegistry.getCampaign(campaignName);
        return getCampaign(campaign, nameRegistry);
    }

    function getCampaign(
        address campaign,
        INameRegistry nameRegistry
    ) public view override returns (Structs.CampaignCommonStateWithName memory) {
        return Structs.CampaignCommonStateWithName(
            ICampaignCommon(campaign).commonState(),
            nameRegistry.getCampaignName(campaign)
        );
    }

    function getCampaignsForIssuerName(
        string memory issuerName,
        address[] memory factories,
        INameRegistry nameRegistry
    ) public view override returns (Structs.CampaignCommonStateWithName[] memory) {
        address issuer = nameRegistry.getIssuer(issuerName);
        return getCampaignsForIssuer(issuer, factories, nameRegistry);
    }

    function getCampaignsForIssuer(
        address issuer,
        address[] memory factories,
        INameRegistry nameRegistry
    ) public view override returns (Structs.CampaignCommonStateWithName[] memory) {
        if (factories.length == 0) { return new Structs.CampaignCommonStateWithName[](0); }
        
        uint256 totalItems = 0;
        uint256[] memory instanceCountPerFactory = new uint256[](factories.length);
        for (uint256 i = 0; i < factories.length; i++) {
            uint256 count = ICampaignFactoryCommon(factories[i]).getInstancesForIssuer(issuer).length;
            totalItems += count;
            instanceCountPerFactory[i] = count;
        }
        if (totalItems == 0) { return new Structs.CampaignCommonStateWithName[](0); }
        
        Structs.CampaignCommonStateWithName[] memory response = new Structs.CampaignCommonStateWithName[](totalItems);
        uint256 position = 0;
        for (uint256 i = 0; i < factories.length; i++) {
            if (instanceCountPerFactory[i] == 0) continue;
            address[] memory instances = ICampaignFactoryCommon(factories[i]).getInstancesForIssuer(issuer);
            for (uint256 j = 0; j < instanceCountPerFactory[i]; j++) {
                ICampaignCommon campaignInterface = ICampaignCommon(instances[j]);
                response[position] = Structs.CampaignCommonStateWithName(
                    campaignInterface.commonState(),
                    nameRegistry.getCampaignName(instances[j])
                );
                position++;
            }
        }

        return response;
    }

    function getCampaignForIssuerNameInvestor(
        string memory issuerName,
        address investor,
        address[] memory factories,
        INameRegistry nameRegistry
    ) public view override returns (Structs.CampaignCommonStateWithNameAndInvestment[] memory) {
        address issuer = nameRegistry.getIssuer(issuerName);
        return getCampaignsForIssuerInvestor(issuer, investor, factories, nameRegistry);
    }

    function getCampaignsForIssuerInvestor(
        address issuer,
        address investor,
        address[] memory factories,
        INameRegistry nameRegistry
    ) public view override returns (Structs.CampaignCommonStateWithNameAndInvestment[] memory) {
        if (factories.length == 0) { return new Structs.CampaignCommonStateWithNameAndInvestment[](0); }
        
        uint256 totalItems = 0;
        uint256[] memory instanceCountPerFactory = new uint256[](factories.length);
        for (uint256 i = 0; i < factories.length; i++) {
            uint256 count = ICampaignFactoryCommon(factories[i]).getInstancesForIssuer(issuer).length;
            totalItems += count;
            instanceCountPerFactory[i] = count;
        }
        if (totalItems == 0) { return new Structs.CampaignCommonStateWithNameAndInvestment[](0); }
        
        Structs.CampaignCommonStateWithNameAndInvestment[] memory response = new Structs.CampaignCommonStateWithNameAndInvestment[](totalItems);
        uint256 position = 0;
        for (uint256 i = 0; i < factories.length; i++) {
            if (instanceCountPerFactory[i] == 0) continue;
            address[] memory instances = ICampaignFactoryCommon(factories[i]).getInstancesForIssuer(issuer);
            for (uint256 j = 0; j < instanceCountPerFactory[i]; j++) {
                ICampaignCommon campaignInterface = ICampaignCommon(instances[j]);
                response[position] = Structs.CampaignCommonStateWithNameAndInvestment(
                    campaignInterface.commonState(),
                    nameRegistry.getCampaignName(instances[j]),
                    campaignInterface.tokenAmount(investor),
                    campaignInterface.investmentAmount(investor)
                );
                position++;
            }
        }

        return response;
    }

    function getCampaignsForAssetName(
        string memory assetName,
        address[] memory factories,
        INameRegistry nameRegistry
    ) public view override returns (Structs.CampaignCommonStateWithName[] memory) {
        address asset = nameRegistry.getAsset(assetName);
        return getCampaignsForAsset(asset, factories, nameRegistry);
    }

    function getCampaignsForAsset(
        address asset,
        address[] memory factories,
        INameRegistry nameRegistry
    ) public view override returns (Structs.CampaignCommonStateWithName[] memory) {
        if (factories.length == 0) { return new Structs.CampaignCommonStateWithName[](0); }
        
        uint256 totalItems = 0;
        uint256[] memory instanceCountPerFactory = new uint256[](factories.length);
        for (uint256 i = 0; i < factories.length; i++) {
            uint256 count = ICampaignFactoryCommon(factories[i]).getInstancesForAsset(asset).length;
            totalItems += count;
            instanceCountPerFactory[i] = count;
        }
        if (totalItems == 0) { return new Structs.CampaignCommonStateWithName[](0); }
        
        Structs.CampaignCommonStateWithName[] memory response = new Structs.CampaignCommonStateWithName[](totalItems);
        uint256 position = 0;
        for (uint256 i = 0; i < factories.length; i++) {
            if (instanceCountPerFactory[i] == 0) continue;
            address[] memory instances = ICampaignFactoryCommon(factories[i]).getInstancesForAsset(asset);
            for (uint256 j = 0; j < instanceCountPerFactory[i]; j++) {
                ICampaignCommon campaignInterface = ICampaignCommon(instances[j]);
                response[position] = Structs.CampaignCommonStateWithName(
                    campaignInterface.commonState(),
                    nameRegistry.getCampaignName(instances[j])
                );
                position++;
            }
        }

        return response;
    }

    function getCampaignsForAssetNameInvestor(
        string memory assetName,
        address investor,
        address[] memory factories,
        INameRegistry nameRegistry
    ) public view override returns (Structs.CampaignCommonStateWithNameAndInvestment[] memory) {
        address asset = nameRegistry.getAsset(assetName);
        return getCampaignsForAssetInvestor(asset, investor, factories, nameRegistry);
    }

    function getCampaignsForAssetInvestor(
        address asset,
        address investor,
        address[] memory factories,
        INameRegistry nameRegistry
    ) public view override returns (Structs.CampaignCommonStateWithNameAndInvestment[] memory) {
        if (factories.length == 0) { return new Structs.CampaignCommonStateWithNameAndInvestment[](0); }
        
        uint256 totalItems = 0;
        uint256[] memory instanceCountPerFactory = new uint256[](factories.length);
        for (uint256 i = 0; i < factories.length; i++) {
            uint256 count = ICampaignFactoryCommon(factories[i]).getInstancesForAsset(asset).length;
            totalItems += count;
            instanceCountPerFactory[i] = count;
        }
        if (totalItems == 0) { return new Structs.CampaignCommonStateWithNameAndInvestment[](0); }
        
        Structs.CampaignCommonStateWithNameAndInvestment[] memory response = new Structs.CampaignCommonStateWithNameAndInvestment[](totalItems);
        uint256 position = 0;
        for (uint256 i = 0; i < factories.length; i++) {
            if (instanceCountPerFactory[i] == 0) continue;
            address[] memory instances = ICampaignFactoryCommon(factories[i]).getInstancesForAsset(asset);
            for (uint256 j = 0; j < instanceCountPerFactory[i]; j++) {
                ICampaignCommon campaignInterface = ICampaignCommon(instances[j]);
                response[position] = Structs.CampaignCommonStateWithNameAndInvestment(
                    campaignInterface.commonState(),
                    nameRegistry.getCampaignName(instances[j]),
                    campaignInterface.tokenAmount(investor),
                    campaignInterface.investmentAmount(investor)
                );
                position++;
            }
        }

        return response;
    }

    function getAssetsForIssuerName(
        string memory issuerName,
        address[] memory factories,
        INameRegistry nameRegistry
    ) public view override returns (Structs.AssetCommonStateWithName[] memory) {
        address issuer = nameRegistry.getIssuer(issuerName);
        return getAssetsForIssuer(issuer, factories, nameRegistry);
    }


    function getAssetsForIssuer(
        address issuer,
        address[] memory factories,
        INameRegistry nameRegistry
    ) public view override returns (Structs.AssetCommonStateWithName[] memory) {
        if (factories.length == 0) { return new Structs.AssetCommonStateWithName[](0); }
        
        uint256 totalItems = 0;
        uint256[] memory instanceCountPerFactory = new uint256[](factories.length);
        for (uint256 i = 0; i < factories.length; i++) {
            uint256 count = IAssetFactoryCommon(factories[i]).getInstancesForIssuer(issuer).length;
            totalItems += count;
            instanceCountPerFactory[i] = count;
        }
        if (totalItems == 0) { return new Structs.AssetCommonStateWithName[](0); }
        
        Structs.AssetCommonStateWithName[] memory response = new Structs.AssetCommonStateWithName[](totalItems);
        uint256 position = 0;
        for (uint256 i = 0; i < factories.length; i++) {
            if (instanceCountPerFactory[i] == 0) continue;
            address[] memory instances = IAssetFactoryCommon(factories[i]).getInstancesForIssuer(issuer);
            for (uint256 j = 0; j < instanceCountPerFactory[i]; j++) {
                IAssetCommon assetInterface = IAssetCommon(instances[j]);
                response[position] = Structs.AssetCommonStateWithName(
                    assetInterface.commonState(),
                    nameRegistry.getAssetName(instances[j])
                );
                position++;
            }
        }

        return response; 
    }

    function getERC20AssetsForIssuer(
        address issuer,
        address[] memory assetFactories,
        address[] memory campaignFactories
    ) public view override returns (Structs.ERC20AssetCommonState[] memory) {
        // CALCULATE RESPONSE SIZE
        uint256 responseItemsCount = countAssetsForIssuer(issuer, assetFactories);
        if (responseItemsCount == 0) { return new Structs.ERC20AssetCommonState[](0); }

        // BUILD RESPONSE
        Structs.ERC20AssetCommonState[] memory response = new Structs.ERC20AssetCommonState[](responseItemsCount);
        uint256 nextResponseItemIndex = 0;
        for (uint256 i = 0; i < assetFactories.length; i++) {
            address[] memory instances = IAssetFactoryCommon(assetFactories[i]).getInstancesForIssuer(issuer);
            for (uint256 j = 0; j < instances.length; j++) {
                IToken token = IToken(instances[j]);
                response[nextResponseItemIndex] = Structs.ERC20AssetCommonState(
                        instances[j],
                        token.decimals(),
                        token.name(),
                        token.symbol(),
                        IAssetCommon(instances[j]).commonState()
                );
                nextResponseItemIndex++;
            }
        }

        // RETURN RESPONSE
        return response;
    }

    function getAssetBalancesForIssuer(
        address issuer,
        address investor,
        address[] memory assetFactories,
        address[] memory campaignFactories
    ) public view override returns (Structs.AssetBalance[] memory) {
        // CALCULATE RESPONSE SIZE
        uint256 responseItemsCount = countAssetsForIssuerInvestor(issuer, investor, assetFactories);
        if (responseItemsCount == 0) { return new Structs.AssetBalance[](0); }

        // BUILD RESPONSE
        Structs.AssetBalance[] memory response = new Structs.AssetBalance[](responseItemsCount);
        uint256 nextResponseItemIndex = 0;
        for (uint256 i = 0; i < assetFactories.length; i++) {
            address[] memory instances = IAssetFactoryCommon(assetFactories[i]).getInstancesForIssuer(issuer);
            for (uint256 j = 0; j < instances.length; j++) {
                IToken token = IToken(instances[j]);
                uint256 tokenBalance = token.balanceOf(investor);
                if (IToken(instances[j]).balanceOf(investor) > 0) { 
                    response[nextResponseItemIndex] = Structs.AssetBalance(
                        instances[j],
                        token.decimals(),
                        token.name(),
                        token.symbol(),
                        tokenBalance,
                        IAssetCommon(instances[j]).commonState()
                    );
                    nextResponseItemIndex++;
                }
            }
        }

        // RETURN RESPONSE
        return response;
    }

    function tokenValue(
        uint256 tokenAmount,
        IAssetCommon token,
        IToken stablecoin,
        uint256 price
    ) external view returns (uint256) {
        return tokenAmount
            * price
            * (10 ** stablecoin.decimals())
            / token.priceDecimalsPrecision()
            / (10 ** IToken(address(token)).decimals());
    }

    function countAssetsForIssuerInvestor(
        address issuer,
        address investor,
        address[] memory assetFactories
    ) public view returns (uint256) {
        if (assetFactories.length == 0) { return 0; }

        // COUNT TOTAL RESPONSE SIZE
        uint256 responseItemsCount = 0;
        for (uint256 i = 0; i < assetFactories.length; i++) {
            address[] memory instances = IAssetFactoryCommon(assetFactories[i]).getInstancesForIssuer(issuer);
            for (uint256 j = 0; j < instances.length; j++) {
                if (IToken(instances[j]).balanceOf(investor) > 0) { 
                    responseItemsCount++;
                }
            }
        }

        return responseItemsCount;
    }

    function countAssetsForIssuer(
        address issuer,
        address[] memory assetFactories
    ) public view returns (uint256) {
        if (assetFactories.length == 0) { return 0; }

        // COUNT TOTAL RESPONSE SIZE
        uint256 responseItemsCount = 0;
        for (uint256 i = 0; i < assetFactories.length; i++) {
            responseItemsCount += IAssetFactoryCommon(assetFactories[i]).getInstancesForIssuer(issuer).length;
        }

        return responseItemsCount;
    }

}

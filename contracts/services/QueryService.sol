 // SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../shared/Structs.sol";
import "../shared/ICampaignFactoryCommon.sol";
import "../shared/IAssetFactoryCommon.sol";
import "../shared/ICampaignCommon.sol";
import "../shared/IAssetCommon.sol";
import "../registry/INameRegistry.sol";

contract QueryService {

    function getCampaignsForIssuerName(
        string memory issuerName,
        address[] memory factories,
        INameRegistry nameRegistry
    ) public view returns (Structs.CampaignCommonStateWithName[] memory) {
        address issuer = nameRegistry.getIssuer(issuerName);
        return getCampaignsForIssuer(issuer, factories, nameRegistry);
    }

    function getCampaignsForIssuer(
        address issuer,
        address[] memory factories,
        INameRegistry nameRegistry
    ) public view returns (Structs.CampaignCommonStateWithName[] memory) {
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
    ) public view returns (Structs.CampaignCommonStateWithNameAndInvestment[] memory) {
        address issuer = nameRegistry.getIssuer(issuerName);
        return getCampaignsForIssuerInvestor(issuer, investor, factories, nameRegistry);
    }

    function getCampaignsForIssuerInvestor(
        address issuer,
        address investor,
        address[] memory factories,
        INameRegistry nameRegistry
    ) public view returns (Structs.CampaignCommonStateWithNameAndInvestment[] memory) {
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
    ) public view returns (Structs.CampaignCommonStateWithName[] memory) {
        address asset = nameRegistry.getAsset(assetName);
        return getCampaignsForAsset(asset, factories, nameRegistry);
    }

    function getCampaignsForAsset(
        address asset,
        address[] memory factories,
        INameRegistry nameRegistry
    ) public view returns (Structs.CampaignCommonStateWithName[] memory) {
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
    ) public view returns (Structs.CampaignCommonStateWithNameAndInvestment[] memory) {
        address asset = nameRegistry.getAsset(assetName);
        return getCampaignsForAssetInvestor(asset, investor, factories, nameRegistry);
    }

    function getCampaignsForAssetInvestor(
        address asset,
        address investor,
        address[] memory factories,
        INameRegistry nameRegistry
    ) public view returns (Structs.CampaignCommonStateWithNameAndInvestment[] memory) {
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

    function getAssetForIssuerName(
        string memory issuerName,
        address[] memory factories,
        INameRegistry nameRegistry
    ) public view returns (Structs.AssetCommonStateWithName[] memory) {
        address issuer = nameRegistry.getIssuer(issuerName);
        return getAssetsForIssuer(issuer, factories, nameRegistry);
    }


    function getAssetsForIssuer(
        address issuer,
        address[] memory factories,
        INameRegistry nameRegistry
    ) public view returns (Structs.AssetCommonStateWithName[] memory) {
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
            }
            position++;
        }

        return response; 
    }

}

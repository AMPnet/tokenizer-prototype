 // SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../shared/Structs.sol";
import "../shared/ICampaignFactoryCommon.sol";
import "../shared/IAssetFactoryCommon.sol";
import "../shared/IIssuerFactoryCommon.sol";
import "../shared/ICampaignCommon.sol";
import "../shared/ISnapshotDistributorCommon.sol";
import "../shared/IAssetCommon.sol";
import "../shared/IIssuerCommon.sol";
import "../shared/IVersioned.sol";
import "../registry/INameRegistry.sol";

contract QueryService is IVersioned {

    string constant public FLAVOR = "QueryServiceV1";
    string constant public VERSION = "1.0.15";

    function flavor() external pure override returns (string memory) { return FLAVOR; }
    function version() external pure override returns (string memory) { return VERSION; } 

    function getIssuers(
        address[] memory factories,
        INameRegistry nameRegistry
    ) public view returns (Structs.IssuerCommonStateWithName[] memory) {
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
    ) public view returns (Structs.IssuerCommonStateWithName memory) {
        address issuer = nameRegistry.getIssuer(issuerName);
        return getIssuer(issuer, nameRegistry);
    }

    function getIssuer(
        address issuer,
        INameRegistry nameRegistry
    ) public view returns (Structs.IssuerCommonStateWithName memory) {
        return Structs.IssuerCommonStateWithName(
            IIssuerCommon(issuer).commonState(),
            nameRegistry.getIssuerName(issuer)
        );
    }

    function getAssetForName(
        string memory assetName,
        INameRegistry nameRegistry
    ) public view returns (Structs.AssetCommonStateWithName memory) {
        address asset = nameRegistry.getAsset(assetName);
        return getAsset(asset, nameRegistry);
    }

    function getAsset(
        address asset,
        INameRegistry nameRegistry
    ) public view returns (Structs.AssetCommonStateWithName memory) {
        return Structs.AssetCommonStateWithName(
            IAssetCommon(asset).commonState(),
            nameRegistry.getAssetName(asset)
        );
    }

    function getCampaignForName(
        string memory campaignName,
        INameRegistry nameRegistry
    ) public view returns (Structs.CampaignCommonStateWithName memory) {
        address campaign = nameRegistry.getCampaign(campaignName);
        return getCampaign(campaign, nameRegistry);
    }

    function getCampaign(
        address campaign,
        INameRegistry nameRegistry
    ) public view returns (Structs.CampaignCommonStateWithName memory) {
        return Structs.CampaignCommonStateWithName(
            ICampaignCommon(campaign).commonState(),
            nameRegistry.getCampaignName(campaign)
        );
    }

    function getSnapshotDistributorForName(
        string memory distributorName,
        INameRegistry nameRegistry
    ) public view returns (Structs.SnapshotDistributorCommonStateWithName memory) {
        address distributor = nameRegistry.getSnapshotDistributor(distributorName);
        return getSnapshotDistributor(distributor, nameRegistry);
    }

    function getSnapshotDistributor(
        address distributor,
        INameRegistry nameRegistry
    ) public view returns (Structs.SnapshotDistributorCommonStateWithName memory) {
        return Structs.SnapshotDistributorCommonStateWithName(
            ISnapshotDistributorCommon(distributor).commonState(),
            nameRegistry.getSnapshotDistributorName(distributor)
        );
    }

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

    function getAssetsForIssuerName(
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
                position++;
            }
        }

        return response; 
    }

}

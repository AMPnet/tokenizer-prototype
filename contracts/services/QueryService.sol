// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../managers/crowdfunding-softcap/ICfManagerSoftcapFactory.sol";
import "../managers/crowdfunding-softcap/ICfManagerSoftcap.sol";
import "../shared/Structs.sol";

contract QueryService {

    struct CampaignWithInvestmentState {
        Structs.CfManagerSoftcapState campaign;
        uint256 tokenAmount;
        uint256 tokenValue;
    }

    function getCampaignsForIssuer(
        address issuer,
        address cfManagerFactoryAddress
    ) external view returns (Structs.CfManagerSoftcapState[] memory) {
        ICfManagerSoftcapFactory cfManagerFactory = ICfManagerSoftcapFactory(cfManagerFactoryAddress);
        address[] memory instances = cfManagerFactory.getInstancesForIssuer(issuer);
        Structs.CfManagerSoftcapState[] memory mapped = new Structs.CfManagerSoftcapState[](instances.length);
        for (uint256 i = 0; i < instances.length; i++) { mapped[i] = ICfManagerSoftcap(instances[i]).getState(); }
        return mapped;
    }
    
    function getCampaignsForIssuerInvestor(
        address issuer,
        address investor,
        address cfManagerFactoryAddress
    ) external view returns (CampaignWithInvestmentState[] memory) {
        ICfManagerSoftcapFactory cfManagerFactory = ICfManagerSoftcapFactory(cfManagerFactoryAddress);
        address[] memory instances = cfManagerFactory.getInstancesForIssuer(issuer);
        CampaignWithInvestmentState[] memory mapped = new CampaignWithInvestmentState[](instances.length);
        for (uint256 i = 0; i < instances.length; i++) {
            ICfManagerSoftcap campaign = ICfManagerSoftcap(instances[i]);
            Structs.CfManagerSoftcapState memory campaignState = campaign.getState();
            mapped[i] = CampaignWithInvestmentState(
                campaignState,
                campaign.tokenAmounts(investor),
                campaign.investments(investor)
            );
        }
        return mapped;
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../shared/IVersioned.sol";
import "../shared/ICampaignFactoryCommon.sol";
import "../managers/ACfManager.sol";
import "./QueryService.sol";
import "../shared/Structs.sol";

interface IInvestService {
    struct PendingInvestmentRecord {
        address investor;
        address campaign;
        uint256 allowance;
        uint256 balance;
        uint256 alreadyInvest;
        bool kycPassed;
    }

    struct InvestmentRecord {
        address investor;
        address campaign;
        uint256 amount;
    }

    struct InvestmentRecordStatus {
        address investor;
        address campaign;
        bool readyToInvest;
    }

    function getPendingFor(
        address _user,
        address _issuer,
        address[] calldata _campaignFactories,
        QueryService queryService,
        INameRegistry nameRegistry
    ) external view returns (PendingInvestmentRecord[] memory);

    function getStatus(InvestmentRecord[] calldata _investments) external view returns (InvestmentRecordStatus[] memory);

    function investFor(InvestmentRecord[] calldata _investments) external;
}

contract InvestService is IVersioned, IInvestService {

    string constant public FLAVOR = "InvestServiceV1";
    string constant public VERSION = "1.0.1";

    function flavor() external pure override returns (string memory) {return FLAVOR;}

    function version() external pure override returns (string memory) {return VERSION;}

    function getPendingFor(
        address _user,
        address _issuer,
        address[] calldata _campaignFactories,
        QueryService _queryService,
        INameRegistry _nameRegistry
    ) external view override returns (PendingInvestmentRecord[] memory) {
        Structs.CampaignCommonStateWithName[] memory campaigns =
        _queryService.getCampaignsForIssuer(_issuer, _campaignFactories, _nameRegistry);
        if (campaigns.length == 0) {return new PendingInvestmentRecord[](0);}
        PendingInvestmentRecord[] memory response = new PendingInvestmentRecord[](campaigns.length);
        for (uint256 i = 0; i < campaigns.length; i++) {
            Structs.CampaignCommonState memory campaign = campaigns[i].campaign;
            response[i] = PendingInvestmentRecord(
                _user,
                campaign.contractAddress,
                IERC20(campaign.stablecoin).allowance(_user, campaign.contractAddress),
                IERC20(campaign.stablecoin).balanceOf(_user),
                IERC20(campaign.asset).balanceOf(_user),
                IIssuerCommon(_issuer).isWalletApproved(_user)
            );
        }
        return response;
    }

    function getStatus(
        InvestmentRecord[] calldata _investments
    ) external view override returns (InvestmentRecordStatus[] memory) {
        if (_investments.length == 0) {return new InvestmentRecordStatus[](0);}

        InvestmentRecordStatus[] memory response = new InvestmentRecordStatus[](_investments.length);
        for (uint256 i = 0; i < _investments.length; i++) {
            InvestmentRecord memory investment = _investments[i];
            ACfManager manager = ACfManager(investment.campaign);
            bool isWhitelisted = manager.isWalletWhitelisted(investment.investor);
            bool enoughFunds = investment.amount >= IERC20(manager.stablecoin()).balanceOf(investment.investor);
            bool readyToInvest = isWhitelisted && enoughFunds;
            response[i] = InvestmentRecordStatus(investment.investor, investment.campaign, readyToInvest);
        }
        return response;
    }

    function investFor(InvestmentRecord[] calldata _investments) public override {
        if (_investments.length == 0) {return;}

        for (uint256 i = 0; i < _investments.length; i++) {
            InvestmentRecord memory investment = _investments[i];
            ACfManager manager = ACfManager(investment.campaign);
            manager.investForBeneficiary(address(this), investment.investor, investment.amount);
            // TODO: maybe release event
        }
    }

}

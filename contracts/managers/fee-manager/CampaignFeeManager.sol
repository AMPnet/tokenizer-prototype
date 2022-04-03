// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./AFeeManager.sol";
import "./ICampaignFeeManager.sol";
import "../../shared/ICampaignCommon.sol";

contract CampaignFeeManager is AFeeManager, ICampaignFeeManager {

    string constant public FLAVOR = "CampaignFeeManagerV1";
    string constant public VERSION = "1.0.32";

    constructor(address _manager, address _treasury) {
        manager = _manager;
        treasury = _treasury;
    }

    function flavor() external pure override returns (string memory) { return FLAVOR; }
    
    function version() external pure override returns (string memory) { return VERSION; }
    
    function setCampaignFee(address campaign, bool initialized, uint256 numerator, uint256 denominator)
        external
        override
        isManager
        isValidFee(numerator, denominator)
    {
        fees[campaign] = FixedFee(initialized, numerator, denominator);
        emit SetCampaignFee(campaign, initialized, numerator, denominator, block.timestamp);
    }

    function calculateFee(address campaign) external view override returns (address, uint256) {
        uint256 fundsRaised = ICampaignCommon(campaign).commonState().fundsRaised;
        return calculateFeeForAmount(campaign, fundsRaised);
    }

}

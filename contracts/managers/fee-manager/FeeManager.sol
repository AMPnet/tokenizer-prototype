// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./AFeeManager.sol";
import "../../shared/IVersioned.sol";
import "../../shared/ICampaignCommon.sol";

interface IFeeManager is IVersioned  {
    event SetCampaignFee(address campaign, bool initialized, uint256 nominator, uint256 denominator, uint256 timestamp);

    function setCampaignFee(address campaign, bool initialized, uint256 numerator, uint256 denominator) external;
    function calculateFee(address campaign) external view returns (address, uint256);
}

contract FeeManager is AFeeManager, IFeeManager {

    string constant public FLAVOR = "FeeManagerV1";
    string constant public VERSION = "1.0.32";

    // Constructor
    constructor(address _manager, address _treasury) {
        manager = _manager;
        treasury = _treasury;
    }

    // IFeeManager IMPL
    function flavor() external pure override returns (string memory) { return FLAVOR; }
    
    function version() external pure override returns (string memory) { return VERSION; }
    
    function setCampaignFee(address campaign, bool initialized, uint256 numerator, uint256 denominator)
        external
        override
        isManager
        isPositiveFee(numerator, denominator) 
    {
        fees[campaign] = FixedFee(initialized, numerator, denominator);
        emit SetCampaignFee(campaign, initialized, numerator, denominator, block.timestamp);
    }

    function calculateFee(address campaign) external view override returns (address, uint256) {
        uint256 fundsRaised = ICampaignCommon(campaign).commonState().fundsRaised;
        return calculateFeeForAmount(campaign, fundsRaised);
    }

}

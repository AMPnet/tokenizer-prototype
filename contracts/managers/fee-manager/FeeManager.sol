// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IFeeManager.sol";
import "../../shared/ICampaignCommon.sol";

contract FeeManager is IFeeManager {

    string constant public FLAVOR = "FeeManagerV1";
    string constant public VERSION = "1.0.21";

    struct FixedFee {
        bool initialized;
        uint256 numerator;
        uint256 denominator;
    }

    // Properties

    address public manager;
    address public treasury;
    FixedFee public defaultFee;
    mapping (address => FixedFee) public fees;
    
    // Events
    event SetDefaultFee(bool initialized, uint256 nominator, uint256 denominator, uint256 timestamp);
    event SetCampaignFee(address campaign, bool initialized, uint256 nominator, uint256 denominato, uint256 timestamp);

    // Constructor

    constructor(address _manager, address _treasury) {
        manager = _manager;
        treasury = _treasury;
    }

    // Modifiers

    modifier isManager() {
        require(msg.sender == manager, "!manager");
        _;
    }

    // Ownership

    function updateTreasury(address newTreasury) external isManager { treasury = newTreasury; }

    function updateManager(address newManager) external isManager { manager = newManager; }

    // IFeeManager IMPL

    function flavor() external pure override returns (string memory) { return FLAVOR; }
    
    function version() external pure override returns (string memory) { return VERSION; }
    
    function setDefaultFee(bool initialized, uint256 numerator, uint256 denominator) external override isManager {
        require(numerator <= denominator, "FeeManager: fee > 1.0");
        require(denominator > 0, "FeeManager: division by zero");
        defaultFee = FixedFee(initialized, numerator, denominator);
        emit SetDefaultFee(initialized, numerator, denominator, block.timestamp);
    }

    function setCampaignFee(address campaign, bool initialized, uint256 numerator, uint256 denominator) external override isManager {
        require(numerator <= denominator, "FeeManager: fee > 1.0");
        require(denominator > 0, "FeeManager: division by zero");
        fees[campaign] = FixedFee(initialized, numerator, denominator);
        emit SetCampaignFee(campaign, initialized, numerator, denominator, block.timestamp);
    }

    function calculateFee(address campaign) external view override returns (address, uint256) {
        uint256 fundsRaised = ICampaignCommon(campaign).commonState().fundsRaised;
        if (fees[campaign].initialized) {
            FixedFee memory fee = fees[campaign];
            return (treasury, fundsRaised * fee.numerator / fee.denominator);
        } else if (defaultFee.initialized) {
            return (treasury, fundsRaised * defaultFee.numerator / defaultFee.denominator);
        } else {
            return (treasury, 0);
        }
    }

}

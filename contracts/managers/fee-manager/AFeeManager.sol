// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

abstract contract AFeeManager {

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

    // Modifiers
    modifier isManager() {
        require(msg.sender == manager, "!manager");
        _;
    }

    modifier isValidFee(uint256 numerator, uint256 denominator) {
        require(numerator <= denominator, "AFeeManager: fee > 1.0");
        require(denominator > 0, "AFeeManager: division by zero");
        _;
    }

    // Ownership
    function updateTreasury(address newTreasury) external isManager { treasury = newTreasury; }

    function updateManager(address newManager) external isManager { manager = newManager; }

    function setDefaultFee(bool initialized, uint256 numerator, uint256 denominator) 
        external 
        isManager 
        isValidFee(numerator, denominator)
    {
        defaultFee = FixedFee(initialized, numerator, denominator);
        emit SetDefaultFee(initialized, numerator, denominator, block.timestamp);
    }

    function calculateFeeForAmount(address account, uint256 amount) public view returns (address, uint256) {
        if (fees[account].initialized) {
            FixedFee memory fee = fees[account];
            return (treasury, amount * fee.numerator / fee.denominator);
        } else if (defaultFee.initialized) {
            return (treasury, amount * defaultFee.numerator / defaultFee.denominator);
        } else {
            return (treasury, 0);
        }
    }
}

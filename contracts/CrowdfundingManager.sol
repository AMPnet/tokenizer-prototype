// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { ISynthetic } from "./interfaces/ISynthetic.sol";

contract CrowdfundingManager is Ownable {

    ISynthetic public synthetic;
    uint256 _minInvestment;
    uint256 _maxInvestment;
    uint256 _endsAt;

    constructor(uint256 minInvestment, uint256 maxInvestment, uint256 endsAt) {
        require(
            _maxInvestment >= _minInvestment,
            "Max investment must be greater than or equal to min investment."
        );
        require(
            _endsAt > block.timestamp,
            "Ends at value has to be in the future."
        );
        minInvestment = _minInvestment;
        maxInvestment = _maxInvestment;
        endsAt = _endsAt;
    }

    function setSynthetic(ISynthetic _synthetic) external {
        require(
            address(synthetic) == address(0),
            "Synthetic address already set."
        );
        require(
            _synthetic.totalShares() >= _minInvestment,
            "Min investment must be less than total Synthetic value (shares)."
        );
        synthetic = _synthetic;
    }

    function invest() public { 
        // TODO: - Implement
    }

}

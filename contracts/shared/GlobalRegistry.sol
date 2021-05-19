// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { IGlobalRegistry } from "./IGlobalRegistry.sol";

contract GlobalRegistry is Ownable, IGlobalRegistry {

    address public override issuerFactory;
    address public override assetFactory;
    address public override cfManagerFactory;
    address public override payoutManagerFactory;

    constructor(
        address _issuerFactory,
        address _assetFactory,
        address _cfManagerFactory,
        address _payoutManagerFactory
    )
    {
        issuerFactory = _issuerFactory;
        assetFactory = _assetFactory;
        cfManagerFactory = _cfManagerFactory;
        payoutManagerFactory = _payoutManagerFactory;
    }

    function updateIssuerFactory(address newIssuerFactory) external onlyOwner {
        issuerFactory = newIssuerFactory;
    }

    function updateAssetFactory(address newAssetFactory) external onlyOwner {
        assetFactory = newAssetFactory;
    }

    function updateCfManagerFactory(address newCfManagerFactory) external onlyOwner {
        cfManagerFactory = newCfManagerFactory;
    }
    
    function updatePayoutManagerFactory(address newPayoutManagerFactory) external onlyOwner {
        payoutManagerFactory = newPayoutManagerFactory;
    }

}

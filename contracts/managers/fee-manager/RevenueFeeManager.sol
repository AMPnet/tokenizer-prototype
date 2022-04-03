// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./AFeeManager.sol";
import "./IRevenueFeeManager.sol";
import "../../services/QueryService.sol";
import "../../shared/Structs.sol";

contract RevenueFeeManager is AFeeManager, IRevenueFeeManager {

    string constant public FLAVOR = "RevenueFeeManagerV1";
    string constant public VERSION = "1.0.32";

    constructor(address _manager, address _treasury) {
        manager = _manager;
        treasury = _treasury;
    }

    function flavor() external pure override returns (string memory) { return FLAVOR; }
    
    function version() external pure override returns (string memory) { return VERSION; }
    
    function setAssetFee(address asset, bool initialized, uint256 numerator, uint256 denominator) 
        external
        override
        isManager 
        isValidFee(numerator, denominator)
    {
        fees[asset] = FixedFee(initialized, numerator, denominator);
        emit SetAssetFee(asset, initialized, numerator, denominator, block.timestamp);
    }

    function setIssuerFee(
        address issuer,
        address queryService,
        address[] calldata factories,
        address nameRegistry,
        bool initialized, 
        uint256 numerator, 
        uint256 denominator
    )
        external
        override
        isManager
        isValidFee(numerator, denominator)
    {
        Structs.AssetCommonStateWithName[] memory assets = 
            IQueryService(queryService).getAssetsForIssuer(
                issuer,
                factories,
                INameRegistry(nameRegistry)
            );
        FixedFee memory fee = FixedFee(initialized, numerator, denominator);
        for (uint256 i = 0; i < assets.length; i++) {
            address asset = assets[i].asset.contractAddress;
            fees[asset] = fee;
            emit SetAssetFee(asset, initialized, numerator, denominator, block.timestamp);
        }
    }

    function calculateFee(address asset, uint256 amount) external view override returns (address, uint256) {
        return calculateFeeForAmount(asset, amount);
    }
}

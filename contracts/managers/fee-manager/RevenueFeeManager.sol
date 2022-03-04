// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./AFeeManager.sol";
import "../../services/QueryService.sol";
import "../../shared/IVersioned.sol";
import "../../shared/Structs.sol";

interface IRevenueFeeManager is IVersioned  {
    event SetAssetFee(address asset, bool initialized, uint256 nominator, uint256 denominator, uint256 timestamp);

    function setAssetFee(address asset, bool initialized, uint256 numerator, uint256 denominator) external;
    function setIssuerFee(
        address issuer,
        QueryService queryService,
        address[] calldata factories,
        INameRegistry nameRegistry,
        bool initialized,
        uint256 numerator,
        uint256 denominator
    ) external;
    function calculateFee(address asset, uint256 amount) external view returns (address, uint256);
} 

contract RevenueFeeManager is AFeeManager, IRevenueFeeManager {

    string constant public FLAVOR = "RevenueFeeManagerV1";
    string constant public VERSION = "1.0.32";

    // Constructor
    constructor(address _manager, address _treasury) {
        manager = _manager;
        treasury = _treasury;
    }

    // IRevenueFeeManager IMPL
    function flavor() external pure override returns (string memory) { return FLAVOR; }
    
    function version() external pure override returns (string memory) { return VERSION; }
    
    function setAssetFee(address asset, bool initialized, uint256 numerator, uint256 denominator) 
        external
        override
        isManager 
        isPositiveFee(numerator, denominator) 
    {
        fees[asset] = FixedFee(initialized, numerator, denominator);
        emit SetAssetFee(asset, initialized, numerator, denominator, block.timestamp);
    }

    function setIssuerFee(
        address issuer,
        QueryService queryService,
        address[] calldata factories,
        INameRegistry nameRegistry,
        bool initialized, 
        uint256 numerator, 
        uint256 denominator
    )
        external
        override
        isManager
        isPositiveFee(numerator, denominator) 
    {
        Structs.AssetCommonStateWithName[] memory assets = queryService.getAssetsForIssuer(issuer, factories, nameRegistry);
        for (uint256 i = 0; i < assets.length; i++) {
            address asset = assets[i].asset.contractAddress;
            fees[asset] = FixedFee(initialized, numerator, denominator);
            emit SetAssetFee(asset, initialized, numerator, denominator, block.timestamp);
        }
    }

    function calculateFee(address asset, uint256 amount) external view override returns (address, uint256) {
        return calculateFeeForAmount(asset, amount);
    }
}

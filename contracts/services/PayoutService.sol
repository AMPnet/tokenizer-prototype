// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../managers/payout-manager/IPayoutManager.sol";
import "../managers/fee-manager/IRevenueFeeManager.sol";
import "../shared/Structs.sol";
import "../shared/IAssetFactoryCommon.sol";
import "../shared/IVersioned.sol";

interface IPayoutService is IVersioned {

    struct PayoutStateForInvestor {
        uint256 payoutId;
        address investor;
        uint256 amountClaimed;
    }

    function getPayoutsForIssuer(
        address issuer,
        address payoutManager,
        address[] memory assetFactories
    ) external view returns (Structs.Payout[] memory);

    function getPayoutStatesForInvestor(
        address investor,
        address payoutManager,
        uint256[] memory payoutId
    ) external view returns(PayoutStateForInvestor[] memory);

    function getPayoutFeeForAssetAndAmount(
        address asset,
        uint256 amount,
        address payoutManager
    ) external view returns (address treasury, uint256 fee);
}

contract PayoutService is IPayoutService {
    
    string constant public FLAVOR = "PayoutServiceV1";
    string constant public VERSION = "1.0.32";

    function flavor() external pure override returns (string memory) { return FLAVOR; }
    function version() external pure override returns (string memory) { return VERSION; }

    function getPayoutsForIssuer(
        address issuer,
        address payoutManager,
        address[] memory assetFactories
    ) external view override returns (Structs.Payout[] memory) {
        uint256 responseItemsCount = 0;
        IPayoutManager payoutManagerInstance = IPayoutManager(payoutManager);
        for (uint256 i = 0; i < assetFactories.length; i++) {
            address[] memory assetInstances = IAssetFactoryCommon(assetFactories[i]).getInstancesForIssuer(issuer);
            for (uint256 j = 0; j < assetInstances.length; j++) {
                responseItemsCount += payoutManagerInstance.getPayoutIdsForAsset(assetInstances[j]).length;
            }
        }
        if (responseItemsCount == 0) { return new Structs.Payout[](0); }
        
        Structs.Payout[] memory payoutsResponse = new Structs.Payout[](responseItemsCount);
        uint256 nextResponseItemIndex = 0;
        for (uint256 i = 0; i < assetFactories.length; i++) {
            address[] memory assetInstances = IAssetFactoryCommon(assetFactories[i]).getInstancesForIssuer(issuer);
            for (uint256 j = 0; j < assetInstances.length; j++) {
                uint256[] memory payoutIds = payoutManagerInstance.getPayoutIdsForAsset(assetInstances[j]);
                for (uint256 k = 0; k < payoutIds.length; k++) {
                    payoutsResponse[nextResponseItemIndex] = payoutManagerInstance.getPayoutInfo(payoutIds[k]);
                    nextResponseItemIndex++;
                }
            }
        }
        return payoutsResponse;
    }

    function getPayoutStatesForInvestor(
        address investor,
        address payoutManager,
        uint256[] memory payoutIds
    ) external view override returns(PayoutStateForInvestor[] memory) {
        uint256 payoutIdsCount = payoutIds.length;
        if (payoutIdsCount == 0) { return new PayoutStateForInvestor[](0); }

        PayoutStateForInvestor[] memory response = new PayoutStateForInvestor[](payoutIdsCount);
        IPayoutManager payoutManagerInstance = IPayoutManager(payoutManager);

        for (uint256 i = 0; i < payoutIdsCount; i++) {
            uint256 payoutId = payoutIds[i];
            response[i] = PayoutStateForInvestor(
                payoutId,
                investor,
                payoutManagerInstance.getAmountOfClaimedFunds(payoutId, investor)
            );
        }
        return response;
    }

    function getPayoutFeeForAssetAndAmount(
        address asset,
        uint256 amount,
        address payoutManager
    ) external view override returns (address treasury, uint256 fee) {
        return IRevenueFeeManager(
            IPayoutManager(payoutManager).getFeeManager()
        ).calculateFee(asset, amount);
    }
}

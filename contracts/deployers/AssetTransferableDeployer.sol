// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IAssetTransferableDeployer.sol";
import "../asset-transferable/AssetTransferable.sol";
import "../shared/Structs.sol";

contract AssetTransferableDeployer is IAssetTransferableDeployer {

    function create(
        string memory flavor,
        string memory version,
        Structs.AssetTransferableFactoryParams memory params
    ) external override returns (address) {
        return address(
            new AssetTransferable(
                Structs.AssetTransferableConstructorParams(
                    flavor,
                    version,
                    params.creator,
                    params.issuer,
                    params.apxRegistry,
                    params.initialTokenSupply,
                    params.whitelistRequiredForRevenueClaim,
                    params.whitelistRequiredForLiquidationClaim,
                    params.name,
                    params.symbol,
                    params.info
                )
            )
        );
    }

}

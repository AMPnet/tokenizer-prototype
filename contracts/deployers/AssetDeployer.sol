// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IAssetDeployer.sol";
import "../asset/Asset.sol";
import "../shared/Structs.sol";

contract AssetDeployer is IAssetDeployer {

    function create(
        string memory flavor,
        string memory version,
        Structs.AssetFactoryParams memory params
    ) external override returns (address) {
        return address(
            new Asset(
                Structs.AssetConstructorParams(
                    flavor,
                    version,
                    params.creator,
                    params.issuer,
                    params.apxRegistry,
                    params.initialTokenSupply,
                    params.transferable,
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

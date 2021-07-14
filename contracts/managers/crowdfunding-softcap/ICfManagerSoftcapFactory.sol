// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../../asset/IAsset.sol";

interface ICfManagerSoftcapFactory {
    function create(
        address owner,
        IAsset assetAddress,
        uint256 initialPricePerToken,
        uint256 softCap,
        bool whitelistRequired,
        string memory info
    ) external returns (address);
    function getInstances() external view returns (address[] memory);
}

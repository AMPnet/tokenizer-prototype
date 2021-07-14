// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./CfManagerSoftcap.sol";
import "./ICfManagerSoftcapFactory.sol";

contract CfManagerSoftcapFactory is ICfManagerSoftcapFactory {

    address[] public instances;

    event CfManagerSoftcapCreated(address indexed creator, address asset, uint256 timestamp);

    function create(
        address owner,
        IAsset assetAddress,
        uint256 initialPricePerToken,
        uint256 softCap,
        bool whitelistRequired,
        string memory info
    ) external override returns (address) {
        uint256 id = instances.length;
        address cfManagerSoftcap = address(new CfManagerSoftcap(
            id,
            owner,
            assetAddress,
            initialPricePerToken,
            softCap,
            whitelistRequired,
            info
        ));
        instances.push(cfManagerSoftcap);
        emit CfManagerSoftcapCreated(owner, address(assetAddress), block.timestamp);
        return cfManagerSoftcap;
    }

    function getInstances() external override view returns (address[] memory) { return instances; }
    
}

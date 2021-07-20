// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Issuer.sol";
import "./IIssuerFactory.sol";

contract IssuerFactory is IIssuerFactory {

    address[] public instances;

    event IssuerCreated(address indexed creator, address asset, uint256 id, uint256 timestamp);

    function create(
        address owner,
        address stablecoin,
        address walletApprover,
        string memory info
    ) external override returns (address)
    {
        uint256 id = instances.length;
        address issuer = address(new Issuer(
            id,
            owner,
            stablecoin,
            walletApprover,
            info
        ));
        instances.push(issuer);
        emit IssuerCreated(owner, issuer, id, block.timestamp);
        return issuer;
    }

    function getInstances() external override view returns (address[] memory) { return instances; }

}

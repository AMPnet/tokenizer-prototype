// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Issuer.sol";
import "./IIssuerFactory.sol";
import "../registry/INameRegistry.sol";

contract IssuerFactory is IIssuerFactory {

    string constant public FLAVOR = "IssuerV1";
    string constant public VERSION = "1.0.13";

    address[] public instances;

    event IssuerCreated(address indexed creator, address issuer, uint256 timestamp);

    function create(
        address owner,
        string memory mappedName,
        address stablecoin,
        address walletApprover,
        string memory info,
        address nameRegistry
    ) external override returns (address)
    {
        INameRegistry registry = INameRegistry(nameRegistry);
        require(
            registry.getIssuer(mappedName) == address(0),
            "IssuerFactory: issuer with this name already exists"
        );
        address issuer = address(new Issuer(
            FLAVOR,
            VERSION,
            owner,
            stablecoin,
            walletApprover,
            info
        ));
        instances.push(issuer);
        registry.mapIssuer(mappedName, issuer);
        emit IssuerCreated(owner, issuer, block.timestamp);
        return issuer;
    }

    function getInstances() external override view returns (address[] memory) { return instances; }

}

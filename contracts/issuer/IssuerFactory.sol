// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Issuer.sol";
import "./IIssuerFactory.sol";

contract IssuerFactory is IIssuerFactory {

    address[] public instances;
    mapping (string => address) public override namespace;

    event IssuerCreated(address indexed creator, address issuer, uint256 id, uint256 timestamp);

    function create(
        address owner,
        string memory ansName,
        address stablecoin,
        address walletApprover,
        string memory info
    ) external override returns (address)
    {
        require(namespace[ansName] == address(0), "IssuerFactory: issuer with this name already exists");
        uint256 id = instances.length;
        address issuer = address(new Issuer(
            id,
            owner,
            ansName,
            stablecoin,
            walletApprover,
            info
        ));
        instances.push(issuer);
        namespace[ansName] = issuer;
        emit IssuerCreated(owner, issuer, id, block.timestamp);
        return issuer;
    }

    function getInstances() external override view returns (address[] memory) { return instances; }

}

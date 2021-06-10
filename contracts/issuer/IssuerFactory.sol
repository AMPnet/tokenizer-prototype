// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Issuer.sol";
import "./IIssuerFactory.sol";

contract IssuerFactory is IIssuerFactory {

    address[] public instances;

    event IssuerCreated(address _asset);

    function create(
        address _owner,
        address _stablecoin, 
        address _registry
    ) external override returns (address) 
    {
        address issuer = address(new Issuer(
            _owner,
            _stablecoin,
            _registry
        ));
        instances.push(issuer);
        emit IssuerCreated(issuer);
        return issuer;
    }

    function getInstances() external override view returns (address[] memory) { return instances; }

}

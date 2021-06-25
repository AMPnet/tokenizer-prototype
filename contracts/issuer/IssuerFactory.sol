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
        address _registry, 
        string memory _info
    ) external override returns (address) 
    {
        uint256 _id = instances.length;
        address issuer = address(new Issuer(
            _id,
            _owner,
            _stablecoin,
            _registry,
            _info
        ));
        instances.push(issuer);
        emit IssuerCreated(issuer);
        return issuer;
    }

    function getInstances() external override view returns (address[] memory) { return instances; }

}

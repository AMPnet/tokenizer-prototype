// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Issuer.sol";
import "./IIssuerFactory.sol";
import "../registry/INameRegistry.sol";

contract IssuerFactory is IIssuerFactory {

    string constant public FLAVOR = "IssuerV1";
    string constant public VERSION = "1.0.28";

    address[] public instances;
    bool public initialized;

    event IssuerCreated(address indexed creator, address issuer, uint256 timestamp);

    constructor(address _oldFactory) { 
        if (_oldFactory != address(0)) { _addInstances(IIssuerFactory(_oldFactory).getInstances()); }
    }

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

    function addInstancesForNewRegistry(
        address oldFactory,
        address oldNameRegistry,
        address newNameRegistry
    ) external override {
        require(!initialized, "IssuerFactory: Already initialized");
        address[] memory _instances = IIssuerFactory(oldFactory).getInstances();
        for (uint256 i = 0; i < _instances.length; i++) {
            address instance = _instances[i];
            instances.push(instance);
            string memory oldName = INameRegistry(oldNameRegistry).getIssuerName(instance);
            if (bytes(oldName).length > 0) { INameRegistry(newNameRegistry).mapIssuer(oldName, instance); }
        }
        initialized = true;
    }

    /////////// HELPERS ///////////

    function _addInstances(address[] memory _instances) private {
        for (uint256 i = 0; i < _instances.length; i++) { instances.push(_instances[i]); }
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../shared/IIssuerFactoryCommon.sol";

interface IIssuerFactory is IIssuerFactoryCommon {
    
    function create(
        address _owner,
        string memory _mappedName,
        address _stablecoin,
        address _walletApprover,
        string memory _info,
        address _nameRegistry
    ) external returns (address);

}

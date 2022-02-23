// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../../shared/IVersioned.sol";

interface IMerkleTreePathValidator is IVersioned {

    function containsNode(
        bytes32 merkleTreeRoot,
        uint256 treeDepth,
        address wallet,
        uint256 balance,
        bytes32[] memory proof
    ) external pure returns (bool);
}

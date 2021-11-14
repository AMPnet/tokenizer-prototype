// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../shared/IVersioned.sol";

interface IMirroredToken is IVersioned {
    function mintMirrored(address wallet, uint256 amount) external;
    function burnMirrored(uint256 amount) external;
}

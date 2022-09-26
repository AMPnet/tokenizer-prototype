// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract NftRewarder is Ownable {

    event AddReward(bytes32 secretHash);
    event ClaimReward(address wallet, bytes32 secretHash);

    struct Reward {
        bytes32 secretHash;
        address token;
        uint256 tokenId;
        uint256 expiresAt;
    }

    mapping (bytes32 => Reward) rewards;
    mapping (bytes32 => bool) claimed;

    constructor(address owner) {
        _transferOwnership(owner);
    }

    function addRewards(Reward[] memory _rewards) public onlyOwner {
        for (uint256 i = 0; i < _rewards.length; i++) {
            rewards[_rewards[i].secretHash] = _rewards[i];
            emit AddReward(_rewards[i].secretHash);
        }
    }

    function claimReward(string memory key) public {
        bytes memory data = abi.encodePacked(address(this), key);
        bytes32 calculatedHash = keccak256(data);
        Reward memory reward = rewards[calculatedHash];
        require(
            reward.secretHash == calculatedHash,
            "Key does not exist!"
        );
        require(
            !claimed[calculatedHash],
            "Reward with this key already claimed!"
        );
        require(
            block.timestamp <= reward.expiresAt,
            "Reward expired!"
        );
        claimed[calculatedHash] = true;
        IERC721(reward.token).safeTransferFrom(
            IERC721(reward.token).ownerOf(reward.tokenId),
            msg.sender,
            reward.tokenId
        );
        emit ClaimReward(msg.sender, calculatedHash);
    }
}

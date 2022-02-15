// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IPayoutManager {

    //------------------------
    //  STRUCTS
    //------------------------
    struct Payout {
        uint256 payoutId; // ID of this payout
        address payoutOwner; // address which created this payout
        string payoutName; // name of the payout (optional)
        string payoutDescriptionIpfsHash; // IPFS hash of the payout description (optional)
        bool isCanceled; // determines if this payout is canceled

        IERC20 asset; // asset for which payout is being made
        uint256 totalAssetAmount; // sum of all asset holdings in the snapshot, minus ignored asset address holdings
        address[] ignoredAssetAddresses; // addresses which aren't included in the payout

        bytes32 assetSnapshotMerkleRoot; // Merkle root hash of asset holdings in the snapshot, without ignored addresses
        uint256 assetSnapshotMerkleDepth; // depth of snapshot Merkle tree
        uint256 assetSnapshotBlockNumber; // snapshot block number
        string assetSnapshotMerkleIpfsHash; // IPFS hash of stored asset snapshot Merkle tree

        IERC20 rewardAsset; // asset issued as payout reward
        uint256 totalRewardAmount; // total amount of reward asset in this payout
        uint256 remainingRewardAmount; // remaining reward asset amount in this payout
    }

    struct CreatePayout {
        IERC20 asset;
        uint256 totalAssetAmount;
        address[] ignoredAssetAddresses;

        string payoutName;
        string payoutDescriptionIpfsHash;

        bytes32 assetSnapshotMerkleRoot;
        uint256 assetSnapshotMerkleDepth;
        uint256 assetSnapshotBlockNumber;
        string assetSnapshotMerkleIpfsHash;

        IERC20 rewardAsset;
        uint256 totalRewardAmount;
    }

    //------------------------
    //  EVENTS
    //------------------------
    event PayoutCreated(uint256 payoutId, address indexed payoutOwner, IERC20 asset, IERC20 rewardAsset, uint256 totalRewardAmount);
    event PayoutCanceled(uint256 payoutId, IERC20 asset);
    event PayoutClaimed(uint256 payoutId, address indexed wallet, uint256 balance, uint256 payoutAmount);

    //------------------------
    //  READ-ONLY FUNCTIONS
    //------------------------
    function getCurrentPayoutId() external view returns (uint256);
    function getPayoutInfo(uint256 _payoutId) external view returns (Payout memory);
    function getPayoutIdsForAsset(address _assetAddress) external view returns (uint256[] memory);
    function getPayoutsForAsset(address _assetAddress) external view returns (Payout[] memory);
    function getPayoutIdsForOwner(address _ownerAddress) external view returns (uint256[] memory);
    function getPayoutsForOwner(address _ownerAddress) external view returns (Payout[] memory);
    function getAmountOfClaimedFunds(uint256 _payoutId, address _wallet) external view returns (uint256);

    //------------------------
    //  STATE CHANGE FUNCTIONS
    //------------------------
    function createPayout(CreatePayout memory _createPayout) external returns (uint256 payoutId);

    function cancelPayout(uint256 _payoutId) external;

    function claim(
        uint256 _payoutId,
        address _wallet,
        uint256 _balance,
        bytes32[] memory _proof
    ) external;
}

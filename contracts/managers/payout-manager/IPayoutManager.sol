// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../../shared/IVersioned.sol";
import "../../shared/Structs.sol";

interface IPayoutManager is IVersioned {

    //------------------------
    //  STRUCTS
    //------------------------
    struct CreatePayout {
        IERC20 asset;
        uint256 totalAssetAmount;
        address[] ignoredAssetAddresses;

        string payoutInfo;

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
    function getPayoutInfo(uint256 _payoutId) external view returns (Structs.Payout memory);
    function getPayoutIdsForAsset(address _assetAddress) external view returns (uint256[] memory);
    function getPayoutsForAsset(address _assetAddress) external view returns (Structs.Payout[] memory);
    function getPayoutIdsForOwner(address _ownerAddress) external view returns (uint256[] memory);
    function getPayoutsForOwner(address _ownerAddress) external view returns (Structs.Payout[] memory);
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

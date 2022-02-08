// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IMerkleTreePathValidator.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract PayoutManager {

    //------------------------
    //  STRUCTS
    //------------------------
    struct Payout {
        uint256 payoutId; // ID of this payout
        address payoutOwner; // address which created this payout
        bool isCanceled; // determines if this payout is canceled

        IERC20 asset; // asset for which payout is being made
        uint256 totalAssetAmount; // sum of all asset holdings in the snapshot, minus ignored asset address holdings
        address[] ignoredAssetAddresses; // addresses which aren't included in the payout

        bytes32 assetSnapshotMerkleRoot; // Merkle root hash of asset holdings in the snapshot, without ignored addresses
        uint256 assetSnapshotMerkleDepth; // depth of snapshot Merkle tree
        uint256 assetSnapshotBlockNumber; // snapshot block number

        IERC20 rewardAsset; // asset issued as payout reward
        uint256 totalRewardAmount; // total amount of reward asset in this payout
        uint256 remainingRewardAmount; // remaining reward asset amount in this payout
    }

    //------------------------
    //  STATE
    //------------------------
    IMerkleTreePathValidator private merkleTreePathValidator;

    uint256 private currentPayoutId = 0; // current payout ID, incremental - if some payout exists, it will always be smaller than this value
    mapping(uint256 => Payout) private payoutsById;
    mapping(address => uint256[]) private payoutsByAssetAddress;
    mapping(uint256 => mapping(address => bool)) private payoutClaims;

    //------------------------
    //  EVENTS
    //------------------------
    event PayoutCreated(uint256 payoutId, address indexed payoutOwner, IERC20 asset, IERC20 rewardAsset, uint256 totalRewardAmount);
    event PayoutCanceled(uint256 payoutId, IERC20 asset);
    event PayoutClaimed(uint256 payoutId, address indexed wallet, uint256 balance, uint256 payoutAmount);

    //------------------------
    //  CONSTRUCTOR
    //------------------------
    constructor(IMerkleTreePathValidator _merkleTreePathValidator) {
        merkleTreePathValidator = _merkleTreePathValidator;
    }

    //------------------------
    //  MODIFIERS
    //------------------------
    modifier payoutExists(uint256 _payoutId) {
        require(_payoutId < currentPayoutId, "PayoutManager: payout with specified ID doesn't exist");
        _;
    }

    modifier payoutNotCanceled(uint256 _payoutId) {
        require(payoutsById[_payoutId].isCanceled == false, "PayoutManager: payout with specified ID is canceled");
        _;
    }

    modifier payoutOwnerOnly(uint256 _payoutId) {
        require(payoutsById[_payoutId].payoutOwner == msg.sender, "PayoutManager: requesting address is not payout owner");
        _;
    }

    modifier payoutNotClaimed(uint256 _payoutId, address _wallet) {
        require(payoutClaims[_payoutId][_wallet] == false, "PayoutManager: payout with specified ID is already claimed for specified wallet");
        _;
    }

    //------------------------
    //  READ-ONLY FUNCTIONS
    //------------------------
    function getPayoutInfo(uint256 _payoutId) public view payoutExists(_payoutId) returns (Payout memory) {
        return payoutsById[_payoutId];
    }

    function getPayoutsForAsset(address _assetAddress) public view returns (Payout[] memory) {
        uint256[] memory payoutIds = payoutsByAssetAddress[_assetAddress];
        Payout[] memory assetPayouts = new Payout[](payoutIds.length);

        for (uint i = 0; i < payoutIds.length; i++) {
            assetPayouts[i] = payoutsById[payoutIds[i]];
        }

        return assetPayouts;
    }

    function hasClaimedFunds(uint256 _payoutId, address _wallet) public view payoutExists(_payoutId) returns (bool) {
        return payoutClaims[_payoutId][_wallet];
    }

    //------------------------
    //  STATE CHANGE FUNCTIONS
    //------------------------
    function createPayout(
        IERC20 _asset,
        uint256 _totalAssetAmount,
        address[] memory _ignoredAssetAddresses,

        bytes32 _assetSnapshotMerkleRoot,
        uint256 _assetSnapshotMerkleDepth,
        uint256 _assetSnapshotBlockNumber,

        IERC20 _rewardAsset,
        uint256 _totalRewardAmount
    ) public returns (uint256 payoutId) {
        // input validations
        require(_totalAssetAmount > 0, "PayoutManager: cannot create payout without holders");
        require(_totalRewardAmount > 0, "PayoutManager: cannot create payout without reward");
        require(_assetSnapshotMerkleDepth > 0, "PayoutManager: Merkle tree depth cannot be zero");

        address payoutOwner = msg.sender;

        // verify that payout owner approved enough reward asset
        require(_totalRewardAmount <= _rewardAsset.allowance(payoutOwner, address(this)), "PayoutManager: insufficient reward asset allowance");

        // create payout
        Payout memory payout = Payout(
            currentPayoutId,
            payoutOwner,
            false, // payout is not canceled
            _asset,
            _totalAssetAmount,
            _ignoredAssetAddresses,
            _assetSnapshotMerkleRoot,
            _assetSnapshotMerkleDepth,
            _assetSnapshotBlockNumber,
            _rewardAsset,
            _totalRewardAmount,
            _totalRewardAmount // remaining reward amount is initially equal to total reward amount
        );

        // store payout
        payoutsById[payout.payoutId] = payout;
        payoutsByAssetAddress[address(_asset)].push(payout.payoutId);

        currentPayoutId += 1;

        // transfer reward asset
        _rewardAsset.transferFrom(payoutOwner, address(this), _totalRewardAmount);

        emit PayoutCreated(payout.payoutId, payoutOwner, _asset, _rewardAsset, _totalRewardAmount);

        return payout.payoutId;
    }

    function cancelPayout(uint256 _payoutId) public payoutExists(_payoutId) payoutOwnerOnly(_payoutId) payoutNotCanceled(_payoutId) {
        Payout storage payout = payoutsById[_payoutId];

        // store remaining funds into local variable to send them later
        uint256 remainingRewardAmount = payout.remainingRewardAmount;

        // set remaining reward funds to 0 and mark payment as canceled
        payout.remainingRewardAmount = 0;
        payout.isCanceled = true;

        // transfer all remaining reward funds to the payout owner
        payout.rewardAsset.transfer(payout.payoutOwner, remainingRewardAmount);

        emit PayoutCanceled(_payoutId, payout.asset);
    }

    function claim(
        uint256 _payoutId,
        address _wallet,
        uint256 _balance,
        bytes32[] memory _proof
    ) public payoutExists(_payoutId) payoutNotCanceled(_payoutId) payoutNotClaimed(_payoutId, _wallet) {
        Payout storage payout = payoutsById[_payoutId];

        // validate Merkle proof to check if payout should be made for (address, balance) pair
        bool containsNode = merkleTreePathValidator.containsNode(
            payout.assetSnapshotMerkleRoot,
            payout.assetSnapshotMerkleDepth,
            _wallet,
            _balance,
            _proof
        );

        require(containsNode, "PayoutManager: requested (address, blaance) pair is not contained in specified payout");

        // calculate reward amount based on percentage of asset holding:
        //   (_balance / payout.totalAssetAmount) gives the holding percentage
        //   (payout.totalRewardAmount * percentage) is the amount that should be paid out
        // this gives the formula:
        //   payout.totalRewardAmount * (_balance / payout.totalAssetAmount)
        // here we can do the multiplication first:
        //   (payout.totalRewardAmount * _balance) / payout.totalAssetAmount
        // which gives us the highest possible precision
        uint256 payoutAmount = (payout.totalRewardAmount * _balance) / payout.totalAssetAmount;

        // in practice this should never happen, but we want to make sure that one payout cannot use funds from another payout
        require(payoutAmount <= payout.remainingRewardAmount, "PayoutManager: not enough funds to issue payout");

        // lower remaining reward funds for the payout
        payout.remainingRewardAmount = payout.remainingRewardAmount - payoutAmount;

        // mark payout as claimed
        payoutClaims[_payoutId][_wallet] = true;

        // send reward funds
        payout.rewardAsset.transfer(_wallet, payoutAmount);

        emit PayoutClaimed(_payoutId, _wallet, _balance, payoutAmount);
    }
}

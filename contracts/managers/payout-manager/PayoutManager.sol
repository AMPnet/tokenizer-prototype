// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IPayoutManager.sol";
import "./IMerkleTreePathValidator.sol";
import "../fee-manager/RevenueFeeManager.sol";
import "../../shared/IVersioned.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract PayoutManager is IPayoutManager {

    string constant public FLAVOR = "PayoutManagerV1";
    string constant public VERSION = "1.0.32";

    //------------------------
    //  STATE
    //------------------------
    IMerkleTreePathValidator private merkleTreePathValidator;
    IRevenueFeeManager private revenueFeeManager;

    uint256 private currentPayoutId = 0; // current payout ID, incremental - if some payout exists, it will always be smaller than this value
    mapping(uint256 => Structs.Payout) private payoutsById;
    mapping(address => uint256[]) private payoutsByAssetAddress;
    mapping(address => uint256[]) private payoutsByOwnerAddress;
    mapping(uint256 => mapping(address => uint256)) private payoutClaims;

    //------------------------
    //  CONSTRUCTOR
    //------------------------
    constructor(address _merkleTreePathValidator, address _revenueFeeManager) {
        require(_merkleTreePathValidator != address(0), "PayoutManager: invalid merkle tree validator provided");
        require(_revenueFeeManager != address(0), "PayoutManager: invalid fee manager provided");
        merkleTreePathValidator = IMerkleTreePathValidator(_merkleTreePathValidator);
        revenueFeeManager = IRevenueFeeManager(_revenueFeeManager);
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
        require(payoutClaims[_payoutId][_wallet] == 0, "PayoutManager: payout with specified ID is already claimed for specified wallet");
        _;
    }

    //------------------------
    //  READ-ONLY FUNCTIONS
    //------------------------
    function flavor() external pure override returns (string memory) { return FLAVOR; }
    
    function version() external pure override returns (string memory) { return VERSION; }

    function getFeeManager() external view override returns (address) { return address(revenueFeeManager); }

    function getCurrentPayoutId() public view override returns (uint256) {
        return currentPayoutId;
    }

    function getPayoutInfo(uint256 _payoutId) public view override payoutExists(_payoutId) returns (Structs.Payout memory) {
        return payoutsById[_payoutId];
    }

    function getPayoutIdsForAsset(address _assetAddress) public view override returns (uint256[] memory) {
        return payoutsByAssetAddress[_assetAddress];
    }

    function getPayoutsForAsset(address _assetAddress) public view override returns (Structs.Payout[] memory) {
        uint256[] memory payoutIds = payoutsByAssetAddress[_assetAddress];
        Structs.Payout[] memory assetPayouts = new Structs.Payout[](payoutIds.length);

        for (uint i = 0; i < payoutIds.length; i++) {
            assetPayouts[i] = payoutsById[payoutIds[i]];
        }

        return assetPayouts;
    }

    function getPayoutIdsForOwner(address _ownerAddress) public view override returns (uint256[] memory) {
        return payoutsByOwnerAddress[_ownerAddress];
    }

    function getPayoutsForOwner(address _ownerAddress) public view override returns (Structs.Payout[] memory) {
        uint256[] memory payoutIds = payoutsByOwnerAddress[_ownerAddress];
        Structs.Payout[] memory ownerPayouts = new Structs.Payout[](payoutIds.length);

        for (uint i = 0; i < payoutIds.length; i++) {
            ownerPayouts[i] = payoutsById[payoutIds[i]];
        }

        return ownerPayouts;
    }

    function getAmountOfClaimedFunds(uint256 _payoutId, address _wallet) public view override payoutExists(_payoutId) returns (uint256) {
        return payoutClaims[_payoutId][_wallet];
    }

    //------------------------
    //  STATE CHANGE FUNCTIONS
    //------------------------
    function createPayout(CreatePayout memory _createPayout) public override returns (uint256 payoutId) {
        // input validations
        require(_createPayout.totalAssetAmount > 0, "PayoutManager: cannot create payout without holders");
        require(_createPayout.totalRewardAmount > 0, "PayoutManager: cannot create payout without reward");
        require(_createPayout.assetSnapshotMerkleDepth > 0, "PayoutManager: Merkle tree depth cannot be zero");

        (address feeAddress, uint256 feeAmount) = revenueFeeManager.calculateFee(address(_createPayout.asset), _createPayout.totalRewardAmount);
        address payoutOwner = msg.sender;
        require(
            (_createPayout.totalRewardAmount + feeAmount) <= _createPayout.rewardAsset.allowance(payoutOwner, address(this)),
            "PayoutManager: insufficient reward asset allowance(reward+fee)"
        );

        // create payout
        Structs.Payout memory payout = Structs.Payout(
            currentPayoutId,
            payoutOwner,
            _createPayout.payoutInfo,
            false, // payout is not canceled
            _createPayout.asset,
            _createPayout.totalAssetAmount,
            _createPayout.ignoredHolderAddresses,
            _createPayout.assetSnapshotMerkleRoot,
            _createPayout.assetSnapshotMerkleDepth,
            _createPayout.assetSnapshotBlockNumber,
            _createPayout.assetSnapshotMerkleIpfsHash,
            _createPayout.rewardAsset,
            _createPayout.totalRewardAmount,
            _createPayout.totalRewardAmount // remaining reward amount is initially equal to total reward amount
        );

        // store payout
        payoutsById[payout.payoutId] = payout;
        payoutsByAssetAddress[address(_createPayout.asset)].push(payout.payoutId);
        payoutsByOwnerAddress[payoutOwner].push(payout.payoutId);

        currentPayoutId += 1;

        // transfer revenue share fee
        if (feeAmount > 0) {
            _createPayout.rewardAsset.transferFrom(payoutOwner, feeAddress, feeAmount);
        }
        // transfer reward asset
        _createPayout.rewardAsset.transferFrom(payoutOwner, address(this), _createPayout.totalRewardAmount);

        emit PayoutCreated(payout.payoutId, payoutOwner, _createPayout.asset, _createPayout.rewardAsset, _createPayout.totalRewardAmount, block.timestamp);

        return payout.payoutId;
    }

    function cancelPayout(uint256 _payoutId) public override payoutExists(_payoutId) payoutOwnerOnly(_payoutId) payoutNotCanceled(_payoutId) {
        Structs.Payout storage payout = payoutsById[_payoutId];

        // store remaining funds into local variable to send them later
        uint256 remainingRewardAmount = payout.remainingRewardAmount;

        // set remaining reward funds to 0 and mark payment as canceled
        payout.remainingRewardAmount = 0;
        payout.isCanceled = true;

        // transfer all remaining reward funds to the payout owner
        payout.rewardAsset.transfer(payout.payoutOwner, remainingRewardAmount);

        emit PayoutCanceled(_payoutId, payout.payoutOwner, payout.asset, payout.rewardAsset, remainingRewardAmount, block.timestamp);
    }

    function claim(
        uint256 _payoutId,
        address _wallet,
        uint256 _balance,
        bytes32[] memory _proof
    ) public override payoutExists(_payoutId) payoutNotCanceled(_payoutId) payoutNotClaimed(_payoutId, _wallet) {
        require(_balance > 0, "PayoutManager: Payout cannot be made for account with zero balance");

        Structs.Payout storage payout = payoutsById[_payoutId];

        // validate Merkle proof to check if payout should be made for (address, balance) pair
        bool containsNode = merkleTreePathValidator.containsNode(
            payout.assetSnapshotMerkleRoot,
            payout.assetSnapshotMerkleDepth,
            _wallet,
            _balance,
            _proof
        );

        require(containsNode, "PayoutManager: requested (address, balance) pair is not contained in specified payout");

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

        // set claimed amount for payout
        payoutClaims[_payoutId][_wallet] = payoutAmount;

        // send reward funds
        payout.rewardAsset.transfer(_wallet, payoutAmount);

        emit PayoutClaimed(_payoutId, _wallet, payout.asset, _balance, payout.rewardAsset, payoutAmount, block.timestamp);
    }
}

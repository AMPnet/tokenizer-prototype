// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "../../asset/IAsset.sol";
import "../payout/IPayoutManager.sol";
import "./IERC20Snapshot.sol";
import { PayoutManagerState, InfoEntry } from "../../shared/Structs.sol";

contract PayoutManager is IPayoutManager {

    using SafeERC20 for IERC20;

    struct Payout {
        uint256 snapshotId;
        string description;
        uint256 amount;
        uint256 totalReleased;
        mapping (address => uint256) released;
    }

    //------------------------
    //  STATE
    //------------------------
    PayoutManagerState private state;
    InfoEntry[] private infoHistory;
    Payout[] public payouts;
    mapping (uint256 => uint256) public snapshotToPayout;
    
    //------------------------
    //  EVENTS
    //------------------------
    event CreatePayout(address creator, uint256 payoutId, uint256 amount, uint256 timestamp);
    event Release(address indexed investor, address asset, uint256 payoutId, uint256 amount, uint256 timestamp);
    event SetInfo(string info, address setter, uint256 timestamp);

    //------------------------
    //  CONSTRUCTOR
    //------------------------
    constructor(uint256 id, address owner, address assetAddress, string memory info) {
        state = PayoutManagerState(
            id,
            owner,
            IAsset(assetAddress),
            info
        );
    }

    //------------------------
    //  MODIFIERS
    //------------------------
    modifier onlyOwner {
        require(msg.sender == state.owner);
        _;
    }

    //------------------------
    //  STATE CHANGE FUNCTIONS
    //------------------------
    function createPayout(string memory description, uint256 amount) external onlyOwner { 
        uint256 snapshotId = state.asset.snapshot();
        _stablecoin().transferFrom(msg.sender, address(this), amount);
        uint256 payoutId = payouts.length;
        Payout storage payout = payouts.push();
        payout.snapshotId = snapshotId;
        payout.description = description;
        payout.amount = amount;
        snapshotToPayout[snapshotId] = payouts.length - 1; 
        emit CreatePayout(msg.sender, payoutId, amount, block.timestamp);
    }

    //------------------------
    //  IPayoutManager IMPL
    //------------------------
    function setInfo(string memory info) external override onlyOwner {
        infoHistory.push(InfoEntry(
            info,
            block.timestamp
        ));
        state.info = info;
        emit SetInfo(info, msg.sender, block.timestamp);
    }

    function release(address account, uint256 snapshotId) external override {
        uint256 payoutId = snapshotToPayout[snapshotId];
        Payout storage payout = payouts[payoutId];
        uint256 sharesAtSnapshot = _shares(account, snapshotId);
        require(sharesAtSnapshot > 0, "Account has no shares.");

        uint256 payment = payout.amount * sharesAtSnapshot / state.asset.totalShares() - payout.released[account];
        require(payment != 0, "Account is not due payment.");

        payout.released[account] += payment;
        payout.totalReleased += payment;
        _stablecoin().safeTransfer(account, payment);
        emit Release(account, address(state.asset), payoutId, payment, block.timestamp);
    }

    function totalShares() external view override returns (uint256) {
        return state.asset.totalShares();
    }

    function totalReleased(uint256 snapshotId) external view override returns (uint256) {
        return payouts[snapshotToPayout[snapshotId]].totalReleased;
    }

    function shares(address account, uint256 snapshotId) external view override returns (uint256) {
        return _shares(account, snapshotId);
    }

    function released(address account, uint256 snapshotId) external view override returns (uint256) {
        return payouts[snapshotToPayout[snapshotId]].released[account];
    }

    function getInfoHistory() external view override returns (InfoEntry[] memory) {
        return infoHistory;
    }

    function getState() external view override returns (PayoutManagerState memory) {
        return state;
    }

    //------------------------
    //  HELPERS
    //------------------------
    function _shares(address account, uint256 snapshotId) internal view returns (uint256) {
        return IERC20Snapshot(address(state.asset)).balanceOfAt(account, snapshotId);
    }

    function _stablecoin() private view returns (IERC20) {
        return IERC20(state.asset.getState().issuer.getState().stablecoin);
    }

}

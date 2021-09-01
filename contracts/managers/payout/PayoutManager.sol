// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "../../asset/IAsset.sol";
import "../../issuer/IIssuer.sol";
import "../payout/IPayoutManager.sol";
import "./IERC20Snapshot.sol";
import "../../shared/Structs.sol";
import "../../shared/IAssetCommon.sol";

contract PayoutManager is IPayoutManager {
    using SafeERC20 for IERC20;

    //------------------------
    //  STATE
    //------------------------
    Structs.PayoutManagerState private state;
    Structs.InfoEntry[] private infoHistory;
    Structs.Payout[] private payouts;
    mapping (uint256 => mapping(address => bool)) public ignoredWalletsMapPerPayout;
    mapping (uint256 => mapping(address => uint256)) public releaseMapPerPayout;
    mapping (uint256 => uint256) public snapshotToPayout;
    
    //------------------------
    //  EVENTS
    //------------------------
    event CreatePayout(address indexed creator, address asset, uint256 payoutId, uint256 amount, uint256 timestamp);
    event Release(address indexed investor, address asset, uint256 payoutId, uint256 amount, uint256 timestamp);
    event SetInfo(string info, address setter, uint256 timestamp);

    //------------------------
    //  CONSTRUCTOR
    //------------------------
    constructor(
        uint256 id,
        address owner,
        string memory ansName,
        uint256 ansId,
        address assetAddress,
        string memory info
    ) {
        require(owner != address(0), "PayoutManager: invalid owner");
        require(assetAddress != address(0), "PayoutManager: invalid asset address");
        address assetFactory = IAssetCommon(assetAddress).getAssetFactory();
        state = Structs.PayoutManagerState(
            id,
            address(this),
            ansName,
            ansId,
            msg.sender,
            owner,
            assetAddress,
            assetFactory,
            0, 0,
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
    function createPayout(string memory description, uint256 amount, address[] memory ignored) external onlyOwner {
        require(amount > 0, "PayoutManager: invalid payout amount provided");
        _stablecoin().transferFrom(msg.sender, address(this), amount);
        uint256 snapshotId = _asset().snapshot();
        uint256 payoutId = payouts.length;
        Structs.Payout storage payout = payouts.push();
        payout.snapshotId = snapshotId;
        payout.description = description;
        payout.amount = amount;
        payout.ignoredWallets = ignored;
        payout.ignoredWallets.push(state.asset);
        uint256 ignoredTokensAmount = _process_ignored_addresses(payoutId, ignored);
        payout.ignoredAmount = ignoredTokensAmount;
        snapshotToPayout[snapshotId] = payouts.length - 1; 
        state.totalPayoutsCreated += 1;
        state.totalPayoutsAmount += amount;
        emit CreatePayout(msg.sender, state.asset, payoutId, amount, block.timestamp);
    }

    //------------------------
    //  IPayoutManager IMPL
    //------------------------
    function setInfo(string memory info) external override onlyOwner {
        infoHistory.push(Structs.InfoEntry(
            info,
            block.timestamp
        ));
        state.info = info;
        emit SetInfo(info, msg.sender, block.timestamp);
    }

    function release(address account, uint256 snapshotId) external override {
        uint256 payoutId = snapshotToPayout[snapshotId];
        require(!ignoredWalletsMapPerPayout[payoutId][account], "PayoutManager: Account has no shares.");
        require(releaseMapPerPayout[payoutId][account] == 0, "PayoutManager: Account has already released funds");
        Structs.Payout storage payout = payouts[payoutId];
        uint256 sharesAtSnapshot = _shares_at(account, snapshotId);
        require(sharesAtSnapshot > 0, "Account has no shares.");
        uint256 nonIgnorableShares = _supply_at(snapshotId) - payout.ignoredAmount;
        uint256 payment = payout.amount * sharesAtSnapshot / nonIgnorableShares;
        require(payment != 0, "Account is not due payment.");
        releaseMapPerPayout[payoutId][account] = payment;
        payout.totalReleased += payment;
        _stablecoin().safeTransfer(account, payment);
        emit Release(account, address(state.asset), payoutId, payment, block.timestamp);
    }
    
    function totalReleased(uint256 snapshotId) external view override returns (uint256) {
        return payouts[snapshotToPayout[snapshotId]].totalReleased;
    }

    function shares(address account, uint256 snapshotId) external view override returns (uint256) {
        return _shares_at(account, snapshotId);
    }

    function released(address account, uint256 snapshotId) external view override returns (uint256) {
        return releaseMapPerPayout[snapshotToPayout[snapshotId]][account];
    }

    function getInfoHistory() external view override returns (Structs.InfoEntry[] memory) {
        return infoHistory;
    }

    function getState() external view override returns (Structs.PayoutManagerState memory) {
        return state;
    }

    function getPayouts() external view override returns (Structs.Payout[] memory) {
        return payouts;
    }

    //------------------------
    //  HELPERS
    //------------------------
    function _process_ignored_addresses(uint256 payoutId, address[] memory accounts) private returns (uint256) {
        uint256 sum;
        IERC20 asset = IERC20(state.asset);
        for (uint i = 0; i < accounts.length; i++) {
            sum += asset.balanceOf(accounts[i]);
            ignoredWalletsMapPerPayout[payoutId][accounts[i]] = true;
        }
        return sum;
    }

    function _shares_at(address account, uint256 snapshotId) internal view returns (uint256) {
        return IERC20Snapshot(state.asset).balanceOfAt(account, snapshotId);
    }

    function _supply_at(uint256 snapshotId) internal view returns (uint256) {
        return IERC20Snapshot(state.asset).totalSupplyAt(snapshotId);
    }

    function _stablecoin() private view returns (IERC20) {
        return IERC20(_issuer().getState().stablecoin);
    }

    function _asset() private view returns (IAsset) {
        return IAsset(state.asset);
    }

    function _issuer() private view returns (IIssuer) {
        return IIssuer(_asset().getState().issuer);
    }

}

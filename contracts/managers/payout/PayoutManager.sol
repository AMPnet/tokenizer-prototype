// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import { IAsset } from "../../asset/IAsset.sol";
import { IPayoutManager } from "../payout/IPayoutManager.sol";
import { IERC20Snapshot } from "./IERC20Snapshot.sol";

contract PayoutManager is Ownable {

    using SafeERC20 for IERC20;

    struct Payout {
        uint256 snapshotId;
        string description;
        uint256 amount;
        uint256 totalReleased;
        mapping (address => uint256) released;
    }

    IAsset public asset;
    Payout[] public payouts;
    mapping (uint256 => uint256) public snapshotToPayout;

    constructor(address owner, address assetAddress)  {
        asset = IAsset(assetAddress);
    }

    function createNewPayout(string memory description, uint256 amount) external onlyOwner {
        IERC20 stablecoin = IERC20(asset.issuer().stablecoin()); 
        uint256 snapshotId = IERC20Snapshot(address(asset)).snapshot();
        stablecoin.transferFrom(msg.sender, address(this), amount);
        
        Payout storage payout = payouts.push();
        payout.snapshotId = snapshotId;
        payout.description = description;
        payout.amount = amount;
        snapshotToPayout[snapshotId] = payouts.length - 1; 
    }

    function release(address account, uint256 snapshotId) external {
        Payout storage payout = payouts[snapshotToPayout[snapshotId]];
        uint256 sharesAtSnapshot = _shares(account, snapshotId);
        require(sharesAtSnapshot > 0, "Account has no shares.");

        uint256 payment = payout.amount * sharesAtSnapshot / asset.totalShares() - payout.released[account];
        require(payment != 0, "Account is not due payment.");

        payout.released[account] += payment;
        payout.totalReleased += payment;
        IERC20(asset.issuer().stablecoin()).safeTransfer(account, payment);
    }

    function totalShares() external view returns (uint256) {
        return asset.totalShares();
    }

    function totalReleased(uint256 snapshotId) external view returns (uint256) {
        return payouts[snapshotToPayout[snapshotId]].totalReleased;
    }

    function shares(address account, uint256 snapshotId) public view returns (uint256) {
        return _shares(account, snapshotId);
    }

    function released(address account, uint256 snapshotId) public view returns (uint256) {
        return payouts[snapshotToPayout[snapshotId]].released[account];
    }

    function _shares(address account, uint256 snapshotId) internal view returns (uint256) {
        return IERC20Snapshot(address(asset)).balanceOfAt(account, snapshotId);
    }

}

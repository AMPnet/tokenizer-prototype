// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../issuer/IIssuer.sol";
import { IssuerState, InfoEntry } from "../shared/Structs.sol";

contract Issuer is IIssuer {

    //------------------------
    //  STATE
    //------------------------
    IssuerState private state;
    InfoEntry[] private infoHistory;
    mapping (address => bool) public approvedWallets;
    mapping (address => bool) private approvedCampaigns;

    //------------------------
    //  EVENTS
    //------------------------
    event WalletApprove(address approver, address wallet, uint256 timestamp);
    event WalletSuspend(address approver, address wallet, uint256 timestamp);
    event ChangeWalletApprover(address oldWalletApprover, address newWalletApprover, uint256 timestamp);
    event SetInfo(string info, address setter, uint256 timestamp);
    event CampaignApprove(address approver, address campaign, uint256 timestamp);
    event CampaignSuspend(address approver, address campaign, uint256 timestamp);

    //------------------------
    //  CONSTRUCTOR
    //------------------------
    constructor(
        uint256 id,
        address owner,
        address stablecoin,
        address walletApprover,
        string memory info
    ) {
        infoHistory.push(InfoEntry(
            info,
            block.timestamp
        ));
        state = IssuerState(
            id,
            owner,
            stablecoin,
            walletApprover,
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

    modifier onlyWalletApprover {
        require(msg.sender == state.walletApprover);
        _;
    }

    //------------------------
    //  STATE CHANGE FUNCTIONS
    //------------------------
    function approveWallet(address wallet) external onlyWalletApprover {
        approvedWallets[wallet] = true;
        emit WalletApprove(msg.sender, wallet, block.timestamp);
    }

    function suspendWallet(address wallet) external onlyWalletApprover {
        approvedWallets[wallet] = false;
        emit WalletSuspend(msg.sender, wallet, block.timestamp);
    }

    function changeWalletApprover(address newWalletApprover) external onlyOwner {
        state.walletApprover = newWalletApprover;
        emit ChangeWalletApprover(state.walletApprover, newWalletApprover, block.timestamp);
    }

    function approveCampaign(address campaign) external onlyOwner {
        approvedCampaigns[campaign] = true;
        emit CampaignApprove(msg.sender, campaign, block.timestamp);
    }

    function suspendCampaign(address campaign) external onlyOwner {
        approvedCampaigns[campaign] = false;
        emit CampaignSuspend(msg.sender, campaign, block.timestamp);
    }

    //------------------------
    //  IIssuer IMPL
    //------------------------
    function setInfo(string memory info) external override onlyOwner {
        infoHistory.push(InfoEntry(
            info,
            block.timestamp
        ));
        state.info = info;
        emit SetInfo(info, msg.sender, block.timestamp);
    }

    function getState() external override view returns (IssuerState memory) { return state; }
    
    function isWalletApproved(address wallet) external view override returns (bool) {
        return approvedWallets[wallet] || approvedCampaigns[wallet];
    }

    function getInfoHistory() external view override returns (InfoEntry[] memory) {
        return infoHistory;
    }

}

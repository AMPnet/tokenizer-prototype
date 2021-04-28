// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { IIssuer } from "./interfaces/IIssuer.sol";
import { Synthetic } from "./Synthetic.sol";
import { CrowdfundingManager } from "./CrowdfundingManager.sol";

contract Issuer is IIssuer, Ownable {

    mapping (address => bool) public approvedWallets;
    Synthetic[] public synthetics;

    modifier walletApproved(address _wallet) {
        require(
            approvedWallets[_wallet],
            "This action is forbidden. Wallet not approved by the Issuer."
        );
        _;
    }

    function approveWallet(address _wallet) external onlyOwner {
        approvedWallets[_wallet] = true;
    }

    function suspendWallet(address _wallet) external onlyOwner {
        approvedWallets[_wallet] = false;
    }

    function createSynthetic(
        uint256 _categoryId,
        uint256 _totalShares,
        Synthetic.SyntheticState _state,
        string memory _name,
        string memory _symbol
    ) external walletApproved(msg.sender) returns (Synthetic) 
    {
        Synthetic synthetic = new Synthetic(
            msg.sender,
            IIssuer(this),
            _state,
            _categoryId,
            _totalShares,
            _name,
            _symbol
        );
        synthetics.push(synthetic);
        return synthetic;
    }

    function createCrowdfundingCampaign() external {
        // TODO: - Implement after CrowdfundingCampaign Contract has been implemented.
    }

    function isWalletApproved(address _wallet) external view override returns (bool) {
        return approvedWallets[_wallet];
    }

}
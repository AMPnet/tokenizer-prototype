// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Payroll is Ownable {

    event AddPayroll(address payee);
    event RemovePayroll(address payee);
    event Claim(address payee);
    event DrainToken(address token, uint256 amount);

    struct PayrollEntry {
        address receiver;
        address token;
        uint256 amount;
        uint256 periodBasis;
        uint256 lastReceivedTimestamp;
    }

    mapping(address => PayrollEntry) payrolls;

    constructor(address owner) {
        _transferOwnership(owner);
    }

    function addPayrolls(PayrollEntry[] memory _payrolls) public onlyOwner {
        for (uint256 i = 0; i < _payrolls.length; i++) {
            address receiver = _payrolls[i].receiver; 
            payrolls[receiver] = _payrolls[i];
            emit AddPayroll(receiver);
        }
    }

    function removePayrolls(address[] memory payees) public onlyOwner {
        for (uint256 i = 0; i < payees.length; i++) {
            address receiver = payees[i];
            delete payrolls[receiver];
            emit RemovePayroll(receiver);
        }
    }

    function claim(address[] memory payees) public {
        for (uint256 i = 0; i < payees.length; i++) {
            _claimForPayee(payees[i]);
        }
    }

    function drain(address tokenAddress) public onlyOwner {
        IERC20 token = IERC20(tokenAddress);
        uint256 amount = token.balanceOf(address(this));
        if (amount > 0) {
            token.transfer(msg.sender, amount);
            emit DrainToken(tokenAddress, amount);
        }
    }

    function _claimForPayee(address payee) internal {
        PayrollEntry memory payrollEntry = payrolls[payee];
        require(
            payrollEntry.receiver == payee,
            "Payroll: does not exist!"
        );
        require(
            block.timestamp > (payrollEntry.lastReceivedTimestamp + payrollEntry.periodBasis),
            "Payroll: next payment not yet unlockd!"
        );
        payrollEntry.lastReceivedTimestamp += payrollEntry.periodBasis;
        IERC20(payrollEntry.token).transfer(payee, payrollEntry.amount);
        emit Claim(payee);
    }

}

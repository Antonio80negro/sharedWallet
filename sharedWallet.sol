// SPDX-License-Identifier: GPL-3
pragma solidity ^0.8.00;

import "http://github.com/OpenZeppelin/openzeppelin-contracts/contracts/utils/math/SafeMath.sol";
import "http://github.com/OpenZeppelin/openzeppelin-contracts/contracts/access/Ownable.sol";


contract SharedWallet is Ownable{

    using SafeMath for uint;

    struct Payment {
        int amount;
        uint timestamp;
    }

    struct Account {
        bool granted;
        uint balance;
        uint allowance;
        uint numPayments;
        mapping (uint => Payment) payments;
    }

    mapping (address => Account) public accounts;

/** EVENTS */

    event depositedMoney(address account, uint amount);

    event withdrawnMoney(address account, uint amount);

    event transferedMoney(address account, uint amount, address to);

    event refundedAccount(address account, uint amount);

    event grantedAccount(address account);

    event changedAllowance(address _account, uint oldAllowance, uint allowance);

    event notEnoughFunds(address account, uint amount, uint balance);

    event notAllowed(address account, uint amount, uint allowance);

/** MODIFIERS  */

    modifier ifAllowed(address account, uint amount){
        if (account != owner()  && amount > accounts[account].allowance) {
            emit notAllowed(account, amount, accounts[account].allowance);
            revert("You are not allowed.");
        }
        if (amount > accounts[account].balance) {
            emit notEnoughFunds(account, amount, accounts[account].balance);
            revert("You don't have enough money.");
        }
        _;
    }

/** PUBLIC FUNCTIONS */

    function deposit() payable public {
        accounts[msg.sender].balance = accounts[msg.sender].balance.add(msg.value);
        accounts[msg.sender].numPayments = accounts[msg.sender].numPayments.add(1);
        accounts[msg.sender].payments[accounts[msg.sender].numPayments] = Payment(int(msg.value), block.timestamp);
        emit depositedMoney(msg.sender, msg.value);
    }

    function withdraw(uint _amount) public ifAllowed(msg.sender, _amount){
        accounts[msg.sender].balance = accounts[msg.sender].balance.sub(_amount);
        accounts[msg.sender].numPayments = accounts[msg.sender].numPayments.add(1);
        accounts[msg.sender].payments[accounts[msg.sender].numPayments] = Payment(int(0 -_amount), block.timestamp);
        payable(msg.sender).transfer(_amount);
        emit withdrawnMoney(msg.sender, _amount);
    }

    function transfer(address payable _to, uint _amount) public ifAllowed(msg.sender, _amount){
        accounts[msg.sender].balance = accounts[msg.sender].balance.sub(_amount);
        accounts[msg.sender].numPayments = accounts[msg.sender].numPayments.add(1);
        accounts[msg.sender].payments[accounts[msg.sender].numPayments] = Payment(int(0 -_amount), block.timestamp);
        _to.transfer(_amount);
        emit transferedMoney(msg.sender, _amount, _to);
    }

    function changeAllowance(address _account, uint _allowance) public onlyOwner {
        uint oldAllowance = accounts[_account].allowance;
        accounts[_account].allowance = _allowance;
        emit changedAllowance(_account, oldAllowance, accounts[_account].allowance);
    }

    function refundAccount(address _account, uint _amount) public onlyOwner {
        require(accounts[msg.sender].balance >= _amount, "Not enough money.");
        accounts[msg.sender].balance = accounts[msg.sender].balance.sub(_amount);
        accounts[_account].balance = accounts[_account].balance.add(_amount);
        accounts[msg.sender].numPayments = accounts[msg.sender].numPayments.add(1);
        accounts[_account].numPayments = accounts[_account].numPayments.add(1);
        accounts[msg.sender].payments[accounts[msg.sender].numPayments] = Payment(int(0 - _amount), block.timestamp);
        accounts[_account].payments[accounts[_account].numPayments] = Payment(int(_amount), block.timestamp);
        emit refundedAccount(_account, _amount);
    }

    function grantAccount(address _account) public onlyOwner {
        accounts[_account].granted = true;
        emit grantedAccount(_account);
}

/** FALLBACK FUNCTIONS */

    receive() external payable {
       deposit();
    }


}

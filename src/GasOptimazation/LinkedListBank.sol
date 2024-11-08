// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
//import {TokenBankV2} from "src/TokenBankV2/TokenBankV2.sol";
contract LinkedListBank{
    mapping(address => address) public _nextUsers; // map链表，每个用户记录了下一个用户
    mapping(address => uint256) public _balances; // 用户余额

    address constant GUARD = address(0);
    constructor() {
        _nextUsers[GUARD] = GUARD;
    }

    receive() external payable{
        deposit();
    }

    function deposit() public payable{
        updateUser(msg.sender);
    }

    function getTop10() public view returns(address[10] memory top10){
        address p = GUARD;
        for(uint256 i = 0; i < 10; i++) {
            top10[i] = _nextUsers[p];
            p = _nextUsers[p];
        }
    }

    function updateUser(address user) public payable{
        (bool yes,) = isExisted(user);
        if(!yes){
            // 若用户不存在则新增用户
            _addUser(user);
            return;
        }
        _balances[user] += msg.value;
    }

    // function withdraw(address user, uint256 amount) public {
        
    // }

    function addUser(address user) public{
        // 插入的 user 不可存在
        (bool yes,) = isExisted(user);
        require(!yes,"user is existed");
        // 按用户余额有序插入，降序
        _addUser(user);
    }

    function _addUser(address user) internal{
        address p = GUARD;
        while(_balances[p] > _balances[_nextUsers[p]]){
            p = _nextUsers[p];
        }
        if(_nextUsers[p]==GUARD){
            _nextUsers[p] = user;
        }else{
            _nextUsers[user] = _nextUsers[p];
            _nextUsers[p] = user;
        }
        _balances[user] = msg.value;
    }

    function removeUser(address user) public{
        (bool yes, address pre) = isExisted(user);
        require(yes,"user is not existed");
        _nextUsers[pre] = _nextUsers[user];
        delete _nextUsers[user];
        delete _balances[user];
    }

    function isExisted(address user) internal view returns(bool, address){
        require(user != GUARD,"user can not be address 0");
        address p = GUARD;
        while (_nextUsers[p] != user && _nextUsers[p]!= GUARD){
            p = _nextUsers[p];
        }
        if(_nextUsers[p] == user){
            return (true, p);
        } 
        return (false, GUARD);
    }
}
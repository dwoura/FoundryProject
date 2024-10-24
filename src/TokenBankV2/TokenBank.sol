// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;


import {IBank} from "./IBank.sol";
import "./IERC20.sol";

contract TokenBank is IBank {
    address public owner;
    struct User{
        IERC20[] assets; // erc20 list
        mapping(IERC20=>uint) balancesOf; // amount of specific erc20 asset
    }
    mapping(address=>User) internal users;

    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);
    constructor(){
        owner = msg.sender;
    }

    receive () external payable{}

    modifier OnlyOwner{
        require(msg.sender==owner, "only owner can do this");
        _;
    }

    function deposit(address depositor,IERC20 token, uint amount) public {
        // call erc20
        // check allowance
        require(amount>0,"amount is empty");
        require(token.allowance(depositor, address(this)) >= amount, "allowance is not enough");
        
        bool success;
        // transferFrom msg.sender to bank
        success = token.transferFrom(depositor,address(this),amount);
        require(success, "failed to call transferFrom");
        // update user info
        updateUserInfo(depositor, token, amount);
    }

    function updateUserInfo(address user, IERC20 token, uint amount) internal {
        bool isExistInAssets;
        for(uint i=0;i<users[user].assets.length;i++){
            if(users[user].assets[i] == token){
                isExistInAssets = true;
                break;
            }
        }
        if(!isExistInAssets){
            users[user].assets.push(token);
        }
        users[user].balancesOf[token] += amount;
    }

    function withdraw(IERC20 token, uint amount) public payable override {
        // admin can withdraw all token
        if(msg.sender == owner){
            require(token.balanceOf(address(this))>=amount,"amount must be greater than balance of this contract");
            token.transfer(owner,amount);
            return;
        }
        uint availAmount = users[msg.sender].balancesOf[token];
        require(availAmount >= amount, "available amount is not enough");
        token.transfer(msg.sender,amount);
        users[msg.sender].balancesOf[token] -= amount;
    }

    function getBalancesOfMsgSender(IERC20 token) public view returns(uint){
        return users[msg.sender].balancesOf[token];
    }

    function getBalancesOf(address addr,IERC20 token) public view returns(uint){
        //IERC20 itoken = IERC20(token);
        return users[addr].balancesOf[token];
    }

    function transferOwnership(address to) public OnlyOwner{
        require(msg.sender!=address(0), "msgsender is wrong");
        owner = to;
    }
}

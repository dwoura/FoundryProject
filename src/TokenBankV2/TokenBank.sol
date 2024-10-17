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

    constructor(){
        owner = msg.sender;
    }

    receive () external payable{}

    function deposit(IERC20 token, uint amount) public payable override {
        // call erc20
        // check allowance
        require(amount>0,"amount is empty");
        bool success;

        // transferFrom msg.sender to bank
        success = token.transferFrom(payable(msg.sender),payable(address(this)),amount);
        require(success, "failed to call transferFrom");
        // update user info
        updateUserInfo(msg.sender, token, amount);
    }

    function updateUserInfo(address user, IERC20 token, uint amount) internal {
        bool isExistInAssets;
        for(uint i=0;i<users[user].assets.length;i++){
            if(isExistInAssets){
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
            bool success = token.approve(msg.sender, amount);
            require(success,"failed to approve");
            token.transfer(owner,amount);
            return;
        }
        uint availAmount = users[msg.sender].balancesOf[token];
        require(availAmount >= amount, "available amount is not enough");
        token.transfer(msg.sender,amount);
        users[msg.sender].balancesOf[token] -= 1;
    }

    function getBalancesOfMsgSender(IERC20 token) public view returns(uint){
        return users[msg.sender].balancesOf[token];
    }
}

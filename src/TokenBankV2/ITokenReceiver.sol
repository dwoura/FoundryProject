// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

interface ITokenReceiver{
    function tokensReceived(address operator,address from,uint256 amount, bytes memory data) external returns(bool);
}

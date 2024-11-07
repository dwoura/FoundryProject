// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Test, console} from "forge-std/Test.sol";
import {LinkedListBank} from "src/GasOptimazation/LinkedListBank.sol";

contract LinkedListBankTest is Test{
    LinkedListBank bank;
    address[] public addresses;
    function setUp() public {
        generateAddresses();
        bank = new LinkedListBank();
    }

    function generateAddresses() internal {
        for (uint256 i = 0; i < 20; i++) {
            addresses.push(vm.addr(uint256(i+1)));
            vm.deal(addresses[i], 100 ether);
        }
    }

    function test_deposit() public {
        // 升序存钱
        for (uint256 i = 0; i < addresses.length; i++) {
            vm.prank(addresses[i]);
            (bool success,) = payable(bank).call{value: i + 1 ether}("");
            assert(success);
        }

        // 降序输出
        uint256 lastUserBalance = 0 ether;
        for (uint256 i = 0; i < 10; i++) {
            address user = bank._nextUsers(addresses[i+1]);
            uint256 balance = bank._balances(user);
            assertGe(balance, lastUserBalance);
            lastUserBalance = balance;
        }
    }
}
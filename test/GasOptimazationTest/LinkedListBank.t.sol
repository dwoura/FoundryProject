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
            (bool success,) = payable(bank).call{value: i*1e18}("");
            assert(success);
        }

        // 降序输出

        address[10] memory top10 = bank.getTop10();
        for (uint256 i = 0; i < 10; i++) {
            console.log("Top 10 addresses: ",i, bank._balances(top10[i]));
        }
    }
}
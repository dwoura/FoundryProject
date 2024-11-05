// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Test, console} from "forge-std/Test.sol";
import {IERC20} from "src/TokenBankV2/IERC20.sol";
import {IDO} from "src/IDO_Stake/IDO.sol";

contract IDOTest is Test{
    IDO ido;
    address idoAddr;

    address fundraiser = makeAddr("fundraiser");
    address alice = makeAddr("alice");
    address bob = makeAddr("bob");
    

    function setUp() public {
        ido = new IDO();
        idoAddr = address(ido);

        vm.deal(alice,100 ether);
        vm.deal(bob,100 ether);

        
    }

    function test_Claim() public {

    }

    function test_Withdraw() public {
        
    }

    function test_Refund() public {
        
    }
}
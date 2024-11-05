// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Test, console} from "forge-std/Test.sol";
import {MyPermitToken} from "src/PermitWhitelist/MyPermitToken.sol";
import {Token} from "src/IDO_Stake/Stake/Token.sol";
import {StakePool} from "src/IDO_Stake/Stake/StakePool.sol";

contract StakeTest is Test{
    MyPermitToken rnt;
    address rntAddr;
    Token esRnt;
    address esRntAddr;
    StakePool stakePool;
    address stakePoolAddr;

    address dev = makeAddr("dev");
    address alice = makeAddr("alice");
    address bob = makeAddr("bob");
    
    uint256 REWARDS_PER_DAY = 1;

    function setUp() public {
        vm.startPrank(dev);
        rnt = new MyPermitToken(dev);
        rntAddr = address(rnt);
        stakePool = new StakePool(); 
        stakePoolAddr = address(stakePool);
        esRnt = new Token(stakePoolAddr, rntAddr);
        esRntAddr = address(esRnt);

        stakePool.init(rntAddr, esRntAddr, REWARDS_PER_DAY);
        rnt.transfer(stakePoolAddr, 1e18 ether);
        vm.stopPrank();


        vm.deal(alice,100 ether);
        vm.deal(bob,100 ether);

        deal(esRntAddr,bob, 10 ether);
    }

    function test_Stake() public {
        deal(rntAddr,alice, 1 ether);

        vm.startPrank(alice);
        rnt.approve(stakePoolAddr, 100 ether);
        stakePool.stake(1 ether);
        vm.stopPrank();
        (uint256 staked,,) = stakePool.stakeInfos(alice);
        assertEq(staked, 1 ether);

        //console.logUint(staked);
        // CanClaimable
        vm.warp(block.timestamp + 1 days);
        vm.prank(alice);
        stakePool.updateStakeInfo(alice);
        (,uint256 unclaimed,) = stakePool.stakeInfos(alice);
        assertEq(unclaimed, 1 ether); // stake RNT 1 ether, get rewards esRNT 1 ether
    }

    function test_Unstake() public {
        deal(rntAddr,alice, 1 ether);

        // stake
        vm.startPrank(alice);
        rnt.approve(stakePoolAddr, 100 ether);
        stakePool.stake(1 ether);
        vm.stopPrank();

        //console.logUint(staked);
        // CanClaimable
        vm.warp(block.timestamp + 1 days);
        vm.prank(alice);
        stakePool.updateStakeInfo(alice);
        //(,uint256 unclaimed,) = stakePool.stakeInfos(alice);
        
        // unstake
        vm.prank(alice);
        stakePool.unstake(1 ether);
        assertEq(rnt.balanceOf(alice), 1 ether);
    }

    function test_WithdrawUnlockedAndBurnLockedToken() public{
        deal(rntAddr,alice, 1 ether);

        // stake
        vm.startPrank(alice);
        rnt.approve(stakePoolAddr, 100 ether);
        stakePool.stake(1 ether);
        vm.stopPrank();

        // claim
        vm.warp(block.timestamp + 1 days);
        vm.startPrank(alice);
        uint lockId = stakePool.claim(); // Mint an equivalent amount of esRNT corresponding to the RNT provided.
        vm.stopPrank();
        assertEq(esRnt.balanceOf(alice), 1 ether);
        assertEq(rnt.balanceOf(alice), 0 ether);

        // 1 day reward
        vm.prank(alice);
        stakePool.withdrawUnlockedAndBurnLockedToken(lockId);
        assertEq(esRnt.balanceOf(alice), 0 ether);
        
    }
}
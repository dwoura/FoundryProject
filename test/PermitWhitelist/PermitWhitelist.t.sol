// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Test, console} from "forge-std/Test.sol";
import {MyPermitToken} from "src/PermitWhitelist/MyPermitToken.sol";
import "src/TokenBankV2/IERC20.sol";
import "forge-std/console.sol";
import {TokenBankV2} from "src/TokenBankV2/TokenBankV2.sol";

contract PermitWhitelistTest is Test {
    MyPermitToken token;
    TokenBankV2 tokenBank;

    IERC20 itoken;
    IERC20 itokenBank;

    uint256 private alicePrivateKey;
    address public alice;
    address public bob = makeAddr("bob");
    
    function setUp() public {
        alicePrivateKey = uint256(keccak256("alice private key"));
        alice = vm.addr(alicePrivateKey);

        vm.prank(alice);
        token = new MyPermitToken();
        tokenBank = new TokenBankV2(address(token));

        itoken = IERC20(address(token));
        itokenBank = IERC20(address(tokenBank));
        
        //console.log("bbbbb",token.balanceOf(alice));
        vm.deal(alice, 1 ether);
    }

    function test_Deposit() public {
        uint256 amount = 100;

        // 先授权给TokenBank合约
        vm.startPrank(alice);
        itoken.approve(address(tokenBank), amount);
        // 调用TokenBank的deposit函数
        tokenBank.deposit(alice,itoken,amount);
        
        // 检查TokenBank合约的余额和用户的存款
        assertEq(token.balanceOf(address(tokenBank)), amount);
        assertEq(tokenBank.getBalancesOf(alice, itoken), amount);
        vm.stopPrank();
    }

    function hashStructor(
        address owner,
        address spender,
        uint256 value,
        uint256 nonce,
        uint256 deadline
    ) public view returns(bytes32){
        bytes32 hashStruct = keccak256(
            abi.encodePacked(
                "\x19\x01",
                token.DOMAIN_SEPARATOR(),
                keccak256(
                    abi.encode(
                        token.getPermitTypehash(),
                        owner,
                        spender,
                        value,
                        nonce,
                        deadline
                    )
                )
            )
        );
        return hashStruct;
    }

    function verifyPermit() public {
        
    }


    function test_PermitDeposit() public {
        vm.startPrank(alice);
        uint256 amount = 100;
        uint256 nonce = token.nonces(alice);
        console.log("nonce",nonce);
        uint256 deadline = block.timestamp + 1 days;

        // eip712 structure message
        bytes32 permitHash = hashStructor(alice,address(tokenBank),amount,nonce,deadline);

        // get v,r,s from signed message
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(alicePrivateKey, permitHash);
        
        // deposit
        tokenBank.permitDeposit(alice, amount,deadline, v, r, s); // verify the first three args with signature v,r,s
        
        assertEq(token.balanceOf(address(tokenBank)), amount);
        assertEq(tokenBank.getBalancesOf(alice, itoken), amount);
        vm.stopPrank();
    }
}
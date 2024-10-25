// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Test, console} from "forge-std/Test.sol";
import {MyPermitToken} from "src/PermitWhitelist/MyPermitToken.sol";
import {IERC20} from "src/TokenBankV2/IERC20.sol";
import "forge-std/console.sol";
import {TokenBankV2} from "src/TokenBankV2/TokenBankV2.sol";
import {MessageHashUtils} from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";
import {EIP712} from "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import {NFTMarket} from "src/NFTMarket/NFTMarket.sol";
import {MyERC721} from "src/NFTMarket/ERC721.sol";

contract PermitWhitelistTest is Test {
    MyPermitToken erc20;
    TokenBankV2 tokenBank;
    MyERC721 erc721;
    NFTMarket nftMarket;

    IERC20 ierc20;
    IERC20 itokenBank;

    uint256 private developerPrivateKey;
    address public developer;
    uint256 private alicePrivateKey;
    address public alice; // nft buyer
    address public bob = makeAddr("bob"); // nft lister
    
    struct Whitelist {
        address developer;
        address nftAddress;
        uint256 buyLimit;
        uint256 deadline;
    }

    function setUp() public {
        // setup account
        alicePrivateKey = uint256(keccak256("alice private key"));
        alice = vm.addr(alicePrivateKey);
        developerPrivateKey = uint256(keccak256("developer private key"));
        developer = vm.addr(developerPrivateKey);

        // setup contract
        vm.startPrank(developer);
        erc20 = new MyPermitToken();
        tokenBank = new TokenBankV2(address(erc20));
        nftMarket = new NFTMarket();
        erc721 = new MyERC721();
        erc20.transfer(alice, 1000000); // prepare enough erc20 tokens
        vm.stopPrank();

        // setup interface
        ierc20 = IERC20(address(erc20));
        itokenBank = IERC20(address(tokenBank));
        
        //console.log("bbbbb",token.balanceOf(alice));
        vm.deal(alice, 1 ether);
        vm.deal(bob, 1 ether);
        
    }

    function test_Deposit() public {
        uint256 amount = 100;
        

        // 先授权给TokenBank合约
        vm.startPrank(alice);
        ierc20.approve(address(tokenBank), amount);
        // 调用TokenBank的deposit函数
        tokenBank.deposit(alice,ierc20,amount);
        
        // 检查TokenBank合约的余额和用户的存款
        assertEq(erc20.balanceOf(address(tokenBank)), amount);
        assertEq(tokenBank.getBalancesOf(alice, ierc20), amount);
        vm.stopPrank();
    }



    function test_PermitDeposit_TokenBank() public {
        address depositor = alice;
        uint depositorPrivateKey = alicePrivateKey;

        uint256 amount = 100;
        uint256 nonce = erc20.nonces(alice);
        console.log("nonce",nonce);
        uint256 deadline = block.timestamp + 1 days;

        vm.startPrank(alice);
        // make eip712 struct hash, and get eip712 digest
        bytes32 permitStructHash = keccak256(abi.encode(
                erc20.getPermitTypehash(),
                depositor,
                address(tokenBank),
                amount,
                nonce,
                deadline
        ));
        bytes32 digest = MessageHashUtils.toTypedDataHash(erc20.DOMAIN_SEPARATOR(), permitStructHash);
        
        // get v,r,s (3 parts of signature) from signed message
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(depositorPrivateKey, digest);
        

        // deposit
        tokenBank.permitDeposit(depositor, amount,deadline, v, r, s); // verify the first three args with signature v,r,s
        
        assertEq(erc20.balanceOf(address(tokenBank)), amount);
        assertEq(tokenBank.getBalancesOf(depositor, ierc20), amount);
        vm.stopPrank();
    }


    function test_PermitBuy_NFTMarket(uint256 price) public {
        vm.assume(price> 0&& price <= 10000);

        address seller = bob;
        uint256 balancesOfSellerBefore = erc20.balanceOf(seller);
        address buyer = alice;
        //uint256 byerPrivateKey = alicePrivateKey;

        uint buyLimit = 2;
        
        vm.startPrank(seller);
        // mint and list on market
        uint tokenId = erc721.mint(seller, "url");
        erc721.approve(address(nftMarket), tokenId);
        nftMarket.list(address(erc721), tokenId, address(erc20), price);
        vm.stopPrank();

        vm.startPrank(developer);
        // 1. developer check if buyer is in whitelist
        // 2. then developer sign msg
        uint256 deadline = block.timestamp + 1 days;
        bytes32 wlDigest = MessageHashUtils.toTypedDataHash(nftMarket.getDomainSeparator(), 
            keccak256(
                abi.encode(
                    nftMarket.getWhiteListTypeHash(),
                    buyer,
                    address(erc721),
                    buyLimit,
                    deadline
                )
            )
        );

        (uint8 v,bytes32 r,bytes32 s) = vm.sign(developerPrivateKey, wlDigest);
        //bytes32 whiteListSig = abi.encodePacked(r,s,v);
        vm.stopPrank();

        vm.startPrank(buyer);
        // buyer alice call permitBuy
        // buyer sign permit
        // bytes32 permitDigest = MessageHashUtils.toTypedDataHash(erc20.DOMAIN_SEPARATOR(), 
        //     keccak256(
        //         abi.encode(
        //             erc20.getPermitTypehash(),
        //             buyer,
        //             address(nftMarket),
        //             price,
        //             deadline
        //         )
        //     )
        // );
        // (uint8 pv,bytes32 pr,bytes32 ps) = vm.sign(byerPrivateKey, permitDigest);
        // bytes permitSig = abi.encodePacked(pr,ps,pv);
        erc20.approve(address(nftMarket), price);

        NFTMarket.WhiteList memory wl = NFTMarket.WhiteList(buyer, address(erc721), buyLimit, deadline); // pack whiteList data that get from web
        
        nftMarket.permitBuy(tokenId, wl,v,r,s);
        vm.stopPrank();

        assertEq(erc20.balanceOf(seller), balancesOfSellerBefore + price);
        assertEq(erc721.ownerOf(tokenId), buyer);
    }
}
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Test, console} from "forge-std/Test.sol";
import {NFTMarket} from "src/NFTMarket/NFTMarket.sol";
import {MyERC721} from "src/NFTMarket/ERC721.sol";
import {ERC20Hook} from "src/NFTMarket/ERC20Hook.sol";
import "forge-std/console.sol";
contract NFTMarketTest is NFTMarket,Test {
    NFTMarket nftMarket;
    MyERC721 erc721;
    ERC20Hook erc20Hook;

    address amy = makeAddr("amy");
    address bob = makeAddr("bob");

    address nftMarketAddr;
    address nftAddr;
    address erc20HookAddr;
    address seller;
    address buyer;
    uint testNftId = 1;
    uint testPrice = 100;

    function setUp() public {
        vm.prank(amy);
        nftMarket = new NFTMarket();
        vm.prank(amy);
        erc20Hook = new ERC20Hook(); //创建 erc20
        vm.prank(bob);
        erc721 = new MyERC721();

        vm.deal(bob, 10000 ether);
        nftMarketAddr = address(nftMarket);
        nftAddr = address(erc721);
        erc20HookAddr = address(erc20Hook);
        seller = bob;
        buyer = amy;
    }

    // function preMintAndApprove() public {
    //     vm.startPrank(bob);
    //     for(uint i = 1; i < 1000; i++) {
    //         erc721.mint(bob,"xx");
    //         erc721.approve(address(nftMarket),i);
    //     }
    //     vm.stopPrank();
        
    // }

    function test_ListSuccess() public {
        vm.startPrank(seller);
        erc721.mint(seller, "seller");
        // 模拟 approve NFT
        erc721.approve(address(nftMarket),testNftId);

        // expectEmit 设置期望的上架事件
        vm.expectEmit(true, true, true, true);
        emit List(seller, nftAddr, testNftId, erc20HookAddr, testPrice, 0);

        // 4. 执行上架操作
        bool success = nftMarket.list(nftAddr, testNftId, erc20HookAddr, testPrice);

        // 5. 断言操作成功
        assertTrue(success);

        // 6. 获取并检查上架状态
        good memory listedNFT = nftMarket.getGoodInfo(nftAddr, testNftId);
        vm.stopPrank();

        assertEq(listedNFT.seller, seller,"not the same seller");
        assertEq(listedNFT.price, testPrice,"not the same price");
        assertEq(listedNFT.isListing, true,"not listing");
    }

    function test_ListNFTFailsForZeroPrice() public {
        vm.startPrank(seller);
        // 尝试上架价格为0的NFT
        vm.expectRevert("price can not be set 0");
        nftMarket.list(nftAddr, testNftId, erc20HookAddr, 0);
        vm.stopPrank();
    }

    // 没有approve
    function test_ListNFTFailsWithoutApproval() public {
        vm.startPrank(seller);

        // 未调用 approve，直接上架
        vm.expectRevert(); // 默认捕获失败消息
        nftMarket.list(nftAddr, testNftId, erc20HookAddr, testPrice);

        vm.stopPrank();
    }

    // 购买成功
    function test_BuyNFTSuccess() public {
        // seller上架nft
        vm.startPrank(seller);
        erc721.mint(seller, "seller");
        erc721.approve(nftMarketAddr,testNftId);
        nftMarket.list(nftAddr, testNftId, erc20HookAddr, testPrice);
        vm.stopPrank();

        // buyer购买
        vm.startPrank(buyer);
        
        vm.expectEmit(true, true, true, true);
        emit Sold(buyer, nftAddr, testNftId, seller, erc20HookAddr, testPrice);

        bytes memory data = abi.encode(nftAddr,testNftId);
        erc20Hook.transferWithCallback(nftMarketAddr, testPrice, data); // 假设发送了正好足够的token

        vm.stopPrank();
    }

    // 自己买自己的nft
    function test_BuyOwnNFTFail() public {
        vm.startPrank(seller);
        erc721.mint(seller, "seller");
        erc721.approve(nftMarketAddr,testNftId);
        nftMarket.list(nftAddr, testNftId, erc20HookAddr, testPrice);

        // 尝试自己购买自己的NFT
        vm.expectRevert("buyer can't be the seller");
        nftMarket.buyNFT(seller, nftAddr, testNftId);

        vm.stopPrank();
    }

    // 测试支付的token数量过多
    function test_BuyNFTWithExcessiveTokensSuccess() public {
        // seller上架nft
        vm.startPrank(seller);
        erc721.mint(seller, "seller");
        erc721.approve(nftMarketAddr,testNftId);
        nftMarket.list(nftAddr, testNftId, erc20HookAddr, testPrice);
        vm.stopPrank();

        // buyer给了过多token
        vm.startPrank(buyer);
        deal(erc20HookAddr,buyer, testPrice + 10);
        erc20Hook.approve(nftMarketAddr, testPrice + 10);
        // 不会revert，购买逻辑中支持超出部分不转走。
        // 事件断言
        vm.expectEmit(true, true, true, true);
        emit Sold(buyer, nftAddr, testNftId, seller, erc20HookAddr, testPrice);
        bool success = nftMarket.buyNFT(buyer, nftAddr, testNftId);
        assertTrue(success);

        vm.stopPrank();
    }

    // 测试支付的token数量过少
    function test_BuyNFTWithInsufficientTokenFail() public {
        // seller上架nft
        vm.startPrank(seller);
        erc721.mint(seller, "seller");
        erc721.approve(nftMarketAddr,testNftId);
        nftMarket.list(nftAddr, testNftId, erc20HookAddr, testPrice);
        vm.stopPrank();

        // buyer支付的token数量不足
        vm.startPrank(buyer);
        deal(erc20HookAddr,buyer, testPrice - 10);

        vm.expectRevert("buyer has no enough erc20 or allowance");
        nftMarket.buyNFT(buyer, nftAddr, testNftId);

        vm.stopPrank();
    }

    // 模糊测试
    /**
        forge-config:default.fuzz.runs=256
        forge-config:default.fuzz.max-test-rejects=50000
    */
    function testFuzz_ListAndBuy(uint256 amount, address randomBuyer) public {
        // 范围控制
        vm.assume(amount >= 0.01 ether && amount <= 10000 ether);
        vm.assume(randomBuyer != address(0) && randomBuyer != seller); // 买家不能是卖家

        // 卖家上架NFT
        vm.startPrank(seller);
        erc721.mint(seller, "seller");
        erc721.approve(nftMarketAddr,testNftId);
        nftMarket.list(nftAddr, testNftId, erc20HookAddr, amount);
        vm.stopPrank();

        // 模拟买家进行购买
        vm.startPrank(randomBuyer);
        deal(erc20HookAddr,randomBuyer, amount);
        erc20Hook.approve(nftMarketAddr, amount);

        // 验证购买成功
        bool success = nftMarket.buyNFT(randomBuyer, nftAddr, testNftId);
        assertTrue(success);

        vm.stopPrank();
    }

    // 不可变测试，NFTMarket不会持有任何token
    function testInvariant_NFTMarketHasNoToken() public {
        // 卖家上架NFT
        vm.startPrank(seller);
        erc721.mint(seller, "seller");
        erc721.approve(nftMarketAddr,testNftId);
        nftMarket.list(nftAddr, testNftId, erc20HookAddr, testPrice);
        vm.stopPrank();

        // 模拟买家进行购买
        vm.startPrank(buyer);
        deal(erc20HookAddr,buyer, testPrice);
        erc20Hook.approve(nftMarketAddr, testPrice);
        vm.stopPrank();
        // 验证 NFTMarket 合约内的 ERC20 代币余额为 0
        assertEq(erc20Hook.balanceOf(nftMarketAddr), 0, "NFTMarket should not hold any tokens");
    }
}
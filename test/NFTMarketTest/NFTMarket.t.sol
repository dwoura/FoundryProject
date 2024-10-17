// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Test, console} from "forge-std/Test.sol";
import {NFTMarket} from "src/NFTMarket/NFTMarket.sol";
import {MyERC721} from "src/NFTMarket/ERC721.sol";
import {ERC20Hook} from "src/NFTMarket/ERC20Hook.sol";
import "forge-std/console.sol";
contract NFTMarketTest is Test {
    NFTMarket nftMarket;
    MyERC721 erc721;
    ERC20Hook erc20Hook;

    address amy = makeAddr("amy");
    address bob = makeAddr("bob");

    function setUp() public {
        vm.prank(amy);
        nftMarket = new NFTMarket();
        vm.prank(amy);
        erc20Hook = new ERC20Hook(); //创建 erc20
        vm.prank(bob);
        erc721 = new MyERC721();
    }

    function doList() internal{
        // bob 上架1号 nft
        vm.startPrank(bob);
        erc721.mint(bob,"xx");
        console.log("no.1 nft first owner",erc721.ownerOf(1));
        erc721.approve(address(nftMarket),1);
        vm.stopPrank();

        vm.startPrank(address(nftMarket));
        erc721.transferFrom(bob ,address(nftMarket),1);
        // bob以100的价格上架1号
        nftMarket.list(address(erc721),1,address(erc20Hook),100);
        vm.stopPrank();
    }

    function test_ListSuccess() public {
        doList();
        // 测试上架成功与失败
        // 断言错误信息和上架事件

        uint[] memory Listing = nftMarket.getListing(address(erc721));
        assert(Listing[0] == 1);
    
    }

    function test_ListFail() public {
        doList();
        // 测试上架成功与失败
        // 断言错误信息和上架事件

        uint[] memory Listing = nftMarket.getListing(address(erc721));
        assert(Listing[0] == 1);
    
    }

    function buyBuyTransferErc20Hook() internal {
        bytes memory data = abi.encode(address(erc721));
        vm.prank(amy); // amy直接转账购买
        erc20Hook.transferWithCallback(address(nftMarket), 100, data); // 转账token给市场
    }

    function test_ListAndBuy() public {
        doList(); // bob上架1号
        console.log("no.1 nft second owner",erc721.ownerOf(1));
        buyBuyTransferErc20Hook(); // amy购买1号
        console.log("no.1 nft third owner",erc721.ownerOf(1));
        assert(erc721.ownerOf(1) == amy); // 确认amy收到1号nft
    }
}
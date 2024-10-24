// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IERC20} from "./IERC20.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "./ITokenReceiver.sol";
import "forge-std/console.sol";

contract NFTMarket {
    // 定义TokenReceiver的接口id, 用于查询 token 是否支持此接口
    bytes4 private constant tokenReceiverInterfaceId = type(ITokenReceiver).interfaceId;

    address public owner;
    //address[] listing; // 已上架的nft地址
    mapping(address=>uint[]) listingNftId; // 已上架的指定nft 暂时没有按价格排序

    struct good{
        uint id;
        uint price; // nft挂单价格（单位：erc20）
        bool isListing; // nft上架状态
        address seller; // nft挂单的卖家
        address currency; // 使用的货币token
        uint listingIndex; // 上架区的索引
    }
    mapping(address=>mapping(uint=>good)) goods; //nft上架信息

    event List(
        address indexed seller,
        address indexed nftAddr,
        uint indexed nftId,
        address currency,
        uint price,
        uint listingIndex
    );

    event Sold(
        address indexed buyer,
        address indexed nftAddr,
        uint indexed nftId,
        address seller,
        address currency,
        uint price
    );

    constructor(){
        owner = msg.sender;
    }

    function getListing(address nftAddr) public view returns(uint[] memory){
        return listingNftId[nftAddr];
    }

    function getGoodInfo(address nftAddr, uint nftId) public view returns(good memory){
        good memory nft = goods[nftAddr][nftId];
        return nft;
    }

    function getListingNftId(address nftAddr) public view returns(uint[] memory){ 
        return listingNftId[nftAddr];
    }

    function list(address nftAddr, uint nftId,address currency,uint price) public returns(bool){
        // 上架，挂单价格：xx个 token
        // 1. nft传入合约中
        // 2. listing中增加库存
        // 3. 上架状态
        require(price > 0,"price can not be set 0");

        // 用户approve nft，市场进行 transferFrom
        IERC721 erc721 = IERC721(nftAddr);
        erc721.transferFrom(msg.sender, address(this), nftId); // 或者是可以加锁？
        //上架nft
        listingNftId[nftAddr].push(nftId);
        //打包货物
        uint listingIndex = listingNftId[nftAddr].length-1;
        goods[nftAddr][nftId] = good(
            nftId,
            price,
            true,
            msg.sender,
            currency,
            listingIndex
        );

        emit List(msg.sender, nftAddr, nftId, currency, price, listingIndex);
        return true;
    }

    function buyNFT(address buyer,address wantedNftAddr, uint nftId) public returns(bool){
        good memory wantedNft = goods[wantedNftAddr][nftId];
        require(buyer!=wantedNft.seller,"buyer can't be the seller");
        _buyNFTWithoutTansferTokenToSeller(buyer, wantedNftAddr, nftId);
        // 若直接购买，需要市场执行transferFrom
        IERC20 erc20 = IERC20(wantedNft.currency);
        require(erc20.balanceOf(buyer) >= erc20.allowance(buyer, address(this)) && erc20.allowance(buyer, address(this)) >= wantedNft.price, "buyer has no enough erc20");
        bool success = erc20.transferFrom(buyer, wantedNft.seller, wantedNft.price); // 暂未设置手续费
        require(success, "failed to transfer token to seller");

        emit Sold(buyer, wantedNftAddr, nftId, wantedNft.seller, wantedNft.currency, wantedNft.price);
        return success;
    }

    function buyNFTWhenTokensReceived(address buyer,address wantedNftAddr, uint nftId) public returns(bool){
        // 若由回调函数调用，直接从市场转出对应代币给卖家
        good memory wantedNft = goods[wantedNftAddr][nftId];
        IERC20 erc20 = IERC20(wantedNft.currency);
        bool success = _buyNFTWithoutTansferTokenToSeller(buyer, wantedNftAddr, nftId);
        require(success, "failed to call buyNFTWhenTokensReceived");
        erc20.transfer(wantedNft.seller, wantedNft.price);

        emit Sold(buyer, wantedNftAddr, nftId, wantedNft.seller, wantedNft.currency, wantedNft.price);
        return true;
    }
    function _buyNFTWithoutTansferTokenToSeller(address buyer,address wantedNftAddr, uint nftId) public returns(bool){
        // listing 减少库存
        // 下架状态
        // 最后，市场转出nft给买家，市场转出token给卖家

        //IERC721 wantedNft = IERC721(wantedNftAddr);
        require(listingNftId[wantedNftAddr].length>0, "no listing nft now");
        good storage wantedNft = goods[wantedNftAddr][nftId];
        require(wantedNft.isListing, "this nft is unlisted");
        // nft卖出前先交换到末尾再删除
        uint[] storage listingNftIds = listingNftId[wantedNftAddr];
        // 设置末尾的上架索引为目标nft的索引，再交换
        uint lastListingNftId = listingNftIds[listingNftIds.length-1];
        uint wantedListingNftId = listingNftIds[wantedNft.listingIndex];
        goods[wantedNftAddr][lastListingNftId].listingIndex = wantedNft.listingIndex; 
        (wantedListingNftId,lastListingNftId) = (lastListingNftId, wantedListingNftId);
        listingNftIds.pop();
        // 下架状态
        wantedNft.isListing = false;
        // 市场转出 nft 给买家
        IERC721 erc721 = IERC721(wantedNftAddr);
        erc721.transferFrom(address(this),buyer,wantedNft.id);
        return true;
        // 市场转出 token给卖家
    }

    // nft地址和 tokenid 封装在 data，可从 data 中取出
    function tokensReceived(address, address from, uint value, bytes calldata data) public returns(bool){
        // 注意限定交易该 nft 使用的token
        // 解码携带的字节码 data 获取想要购买的 nft 地址。
        (address wantedNftAddr, uint tokenId )= abi.decode(data, (address,uint));

        good memory wantedNft = goods[wantedNftAddr][tokenId]; 
        require(msg.sender == wantedNft.currency, "don't support this currency"); // 限定支持购买该种 nft 的货币

        //转账erc20给 market 合约，触发tokensReceived()进来自动购买，listing pop。
        require(wantedNft.isListing, "none of this nft address is listing");
        require(value >= wantedNft.price, "buyer has no enough erc20");
        buyNFTWhenTokensReceived(from,wantedNftAddr, tokenId); //暂时默认购买 listing 最后一个
        return true;
    }
}

// 直接转账进来钱在市场里，需要由市场转到卖家账户
// 区分回调与非回调进入 buy
// require(IERC165(msg.sender).supportsInterface(tokenReceiverInterfaceId) ,"not expected token "); 这个是用作区分不同协议。例如市场限定转入 erc20和 erc721，就需要用这个作为区分。
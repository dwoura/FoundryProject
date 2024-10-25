// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {EIP712} from "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import {IERC20} from "./IERC20.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "./ITokenReceiver.sol";
import "forge-std/console.sol";
import {IERC20Permit} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Permit.sol";

contract NFTMarket is EIP712{
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

    // EIP712
    struct WhiteList {
        address user;          // 白名单用户的地址
        address nftAddr;       // 允许购买的 nft
        uint256 buyLimit;      // 购买数量
        uint256 deadline;      // 签名的有效期
    }
    bytes32 DOMAIN_SEPARATOR;
    bytes32 WHITELIST_TYPEHASH = keccak256("WhiteList(address user,address nftAddr,uint256 buyLimit,uint256 deadline)");

    mapping(address=>mapping(address=>uint256)) buyLimitMap; // nft buying limit

    error InvalidSignature(address signer, address whitelistAddr);

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

    constructor() EIP712("NFTMarket", "1"){
        owner = msg.sender;

        DOMAIN_SEPARATOR = getDomainSeparator(); // set domain separator
    }

    // eip712
    function getDomainSeparator() public view returns(bytes32){
        return _domainSeparatorV4();
    }

    function getWhiteListTypeHash() public view returns(bytes32){
        return WHITELIST_TYPEHASH;
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

    // new func
    function permitBuy(uint tokenId, WhiteList memory whitelist, uint8 v, bytes32 r, bytes32 s) public {
        // 
        require(block.timestamp <= whitelist.deadline, "Signature expired");
        
        // 拿参数包装白名单成712结构的 data，如果能够和 vrs 一起恢复出项目方钱包地址，说明确实是项目方签名过的白名单用户。
        // 实际上就是需要一份相同信息的明文去匹配暗文，提取并判断谁签署的暗文
        // _hashTypedDataV4, to struct data, is from EIP712.sol
        bytes32 digest = _hashTypedDataV4(keccak256(abi.encode( 
            keccak256("WhiteList(address user,address nftAddr,uint256 buyLimit,uint256 deadline)"),
            whitelist.user,
            whitelist.nftAddr,
            whitelist.buyLimit,
            whitelist.deadline
        )));

        // verify sig is signed from developer
        address signer = ecrecover(digest, v, r, s);
        if(signer != owner){
            revert InvalidSignature(signer, whitelist.user);
        }

        uint256 userBuyingNums = buyLimitMap[whitelist.user][whitelist.nftAddr];
        require(userBuyingNums < whitelist.buyLimit, "buying limit");

        // decode permit sig and call erc20 permit to verify sig
        //good memory wantedNft= goods[whitelist.nftAddr][tokenId];
        //IERC20Permit itoken = IERC20Permit(address(wantedNft.currency));
        //itoken.permit(msg.sender, address(this), wantedNft.price, whitelist.deadline, pv, pr, ps); // do approve here

        bool success = buyNFT(whitelist.user, whitelist.nftAddr, tokenId);
        require(success, "failed to buy NFT");

        userBuyingNums++;

    }

    function buyNFT(address buyer,address wantedNftAddr, uint nftId) public returns(bool){
        good memory wantedNft = goods[wantedNftAddr][nftId];
        require(buyer!=wantedNft.seller,"buyer can't be the seller");
        _buyNFTWithoutTansferTokenToSeller(buyer, wantedNftAddr, nftId);
        // 若直接购买，需要市场执行transferFrom
        IERC20 erc20 = IERC20(wantedNft.currency);
        require(erc20.balanceOf(buyer) >= erc20.allowance(buyer, address(this)) && erc20.allowance(buyer, address(this)) >= wantedNft.price, "buyer has no enough erc20 or allowance");
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
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;
import "forge-std/console.sol";
import {Test, console} from "forge-std/Test.sol";
import {Upgrades, Options} from "openzeppelin-foundry-upgrades/Upgrades.sol";
import {ProxyAdmin} from "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
import {NFTMarketLogicV1} from "src/UpgradeableAndMinimalProxy/NFTMarket/NFTMarketLogicV1.sol";
import {NFTMarketLogicV2} from "src/UpgradeableAndMinimalProxy/NFTMarket/NFTMarketLogicV2.sol";
import {MyERC721} from "src/NFTMarket/ERC721.sol";
import {MessageHashUtils} from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";
import {MyPermitToken} from "src/PermitWhitelist/MyPermitToken.sol";
// import {ITransparentUpgradeableProxy,ProxyAdmin} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
contract InscriptionFactoryProxyTesst is Test {
    address proxyAddr;

    NFTMarketLogicV1 logicV1;
    address logicV1Addr;

    NFTMarketLogicV2 logicV2;
    address logicV2Addr;

    MyERC721 nft;
    address nftAddr;

    uint256 NFTID;

    MyPermitToken erc20;
    address erc20Addr;

    // ITransparentUpgradeableProxy factoryProxy;

    address dev = makeAddr("dev");
    uint256 alicePvkey = uint256(1);
    address alice = vm.addr(alicePvkey);
    address bob = makeAddr("bob");

    function setUp() public {
        // setup logic v1
        logicV1 = new NFTMarketLogicV1();
        
        // setup proxy
        bytes memory initializerData = abi.encodeWithSignature("initialize()");
        vm.prank(dev); // 管理合约地址
        proxyAddr = Upgrades.deployTransparentProxy("NFTMarketLogicV1.sol:NFTMarketLogicV1", dev, initializerData); // initial是为了使得逻辑函数使用存储合约的存储空间

        //factoryProxy = ITransparentUpgradeableProxy(proxyAddr);

        // setup logic v2
        logicV2 = new NFTMarketLogicV2();
        // wait for dev initial

        nft = new MyERC721();
        nftAddr = address(nft);

        vm.deal(alice, 1 ether);
        vm.prank(alice);
        NFTID = nft.mint(alice, "xxx");

        erc20 = new MyPermitToken(dev);
        erc20Addr = address(erc20);
    }

    function test_PermitList() public{
        vm.deal(dev, 10 ether);

        // upgrade with initialize
        bytes memory data = abi.encodeWithSignature("initialize()");
        
        Options memory opts;
        // tips: upgradeProxy only in testing
        Upgrades.upgradeProxy(proxyAddr,"NFTMarketLogicV2.sol:NFTMarketLogicV2",data,opts,dev);

        // alice do permitList 
        vm.startPrank(alice);
        nft.setApprovalForAll(proxyAddr, true); // approveAll first
        bytes32 permitStructHash = keccak256(
            abi.encode(
                nftAddr ,
                NFTID,
                erc20Addr,
                1 ether
            )
        );
        NFTMarketLogicV2 proxyLogicV2 = NFTMarketLogicV2(proxyAddr);
        bytes32 digest = MessageHashUtils.toTypedDataHash(
            proxyLogicV2.getDomainSeparator(),
            permitStructHash
        ); 
        (uint8 v, bytes32 r, bytes32 s)  = vm.sign(alicePvkey, digest);

        NFTMarketLogicV2(proxyAddr).permitList(nftAddr,NFTID, erc20Addr,1 ether,v,r,s); // do list with permit
        vm.stopPrank();
        
        // bob do buy
        deal(erc20Addr,bob,10 ether);
        vm.startPrank(bob);
        erc20.approve(proxyAddr, 1 ether);
        uint256 erc20Before = erc20.balanceOf(bob);
        NFTMarketLogicV2(proxyAddr).buyNFT(bob, nftAddr,NFTID);
        uint256 erc20After = erc20.balanceOf(bob);
        vm.stopPrank();
        assertEq(erc20Before - erc20After, 1 ether);
        assertEq(nft.ownerOf(NFTID), bob);

    }
}
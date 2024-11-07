// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "forge-std/console.sol";
import {Test, console} from "forge-std/Test.sol";
import {InscriptionFactoryProxy} from "src/UpgradeableAndMinimalProxy/InscriptionFactory/InscriptionFactoryProxy.sol";
import {Inscription} from "src/UpgradeableAndMinimalProxy/InscriptionFactory/Inscription.sol";
import {InscriptionFactoryLogicV1} from "src/UpgradeableAndMinimalProxy/InscriptionFactory/InscriptionFactoryLogicV1.sol";
import {InscriptionFactoryLogicV2} from "src/UpgradeableAndMinimalProxy/InscriptionFactory/InscriptionFactoryLogicV2.sol";
import {ITransparentUpgradeableProxy,ProxyAdmin} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
contract InscriptionFactoryProxyTest is Test {
    InscriptionFactoryProxy factoryProxy;
    address proxyAddr;

    Inscription inscription;
    address inscriptionAddr;

    InscriptionFactoryLogicV1 factoryLogicV1;
    address factoryLogicV1Addr;

    InscriptionFactoryLogicV2 factoryLogicV2;
    address factoryLogicV2Addr;

    address dev = makeAddr("dev");
    address alice = makeAddr("alice");
    address bob = makeAddr("bob");

    uint256 MINT_FEE = 0.001 ether;
    uint256 AMOUNT_PER_MINT = 1000;
    function setUp() public {
        // 旧逻辑合约
        factoryLogicV1 = new InscriptionFactoryLogicV1();
        factoryLogicV1Addr = address(factoryLogicV1);
        
        // set logic v1 first
        //salt bytes32(uint256(0x00000000000002025010000000000000000000d3af2663da51c10215000000))
        factoryProxy = new InscriptionFactoryProxy(factoryLogicV1Addr,dev,"");
        proxyAddr = address(factoryProxy);

        // 先生成模板铭文，后面可用于最小代理Clone
        inscription = new Inscription();
        inscription.initialize("DwouraInsc", 21000000, 1000, proxyAddr);
        inscriptionAddr = address(inscription);
    }

    function test_InscriptionFactoryProxy_V1() public{
        vm.deal(dev, 10 ether);

        vm.startPrank(dev);
        // execute deploy
        bytes memory data = abi.encodeWithSignature("deployInscription(string,uint256,uint256)", "DwouraInsc", 21000000, AMOUNT_PER_MINT);
        (bool success,) = proxyAddr.call(data);
        require(success, "Proxy call to deployInscription failed");
        success = false;
        // data = abi.encodeWithSignature("inscriptionAddresses()");

        // 读取插槽中动态地址数组
        bytes32 slot0 = bytes32(uint256(0));

        // 读取数组长度
        uint256 arrLen = uint256(vm.load(proxyAddr, slot0));
        bytes32 firstElementPosition = keccak256(abi.encode(slot0));

        // 读取第一个元素
        bytes32 firstElementData = vm.load(proxyAddr, firstElementPosition);
        vm.stopPrank();

        assertEq(arrLen, 1);
        address inscAddr = address(uint160(uint256(firstElementData)));
        console.logAddress(inscAddr);

        // test v1 mint
        data = abi.encodeWithSignature("mintInscription(address)", inscAddr);
        vm.prank(alice);
        (success,) = proxyAddr.call(data);
        require(success, "Proxy call to mintInscription failed");
        assertEq(Inscription(inscAddr).balanceOf(alice), AMOUNT_PER_MINT); // perMint is 1000
    }

    function test_InscriptionFactoryProxy_UpgradeFromV1ToV2() public{
        vm.deal(dev, 10 ether);
        uint256 ethBalanceBefore = dev.balance;
        
        // proxy alreay setup logic v1 first
        // Upgrade to V2
        // 注意代理合约用的是 proxyAdmin 的合约地址作为管理员地址！！！
        address proxyAdminAddress = factoryProxy.proxyAdmin(); // 代理合约 admin 记录的是proxyAdmin合约地址
        ProxyAdmin devProxyAdmin = ProxyAdmin(proxyAdminAddress);
        ITransparentUpgradeableProxy iproxy = ITransparentUpgradeableProxy(proxyAddr);

        // 新的逻辑合约
        factoryLogicV2 = new InscriptionFactoryLogicV2(); // setup inscriptionTemplate
        factoryLogicV2Addr = address(factoryLogicV2);

        // 先升级，再用代理合约调用初始化，目的是为了使用代理合约的存储
        bytes memory data = abi.encodeWithSignature("initialize(address,uint256)", inscriptionAddr, MINT_FEE);
        vm.prank(dev); // 管理合约地址
        devProxyAdmin.upgradeAndCall(iproxy,factoryLogicV2Addr, data);

        vm.startPrank(dev);
        // initialize
        
        // execute V2 deploy
        data = abi.encodeWithSignature("deployInscription(string,uint256,uint256)", "DwouraInsc", 21000000, AMOUNT_PER_MINT);
        (bool success,) = proxyAddr.call(data);
        require(success, "Proxy call to deployInscription failed");
        
        // 获取 deploy 的合约地址
        address inscAddr = factoryProxy.inscriptionAddresses(0);  
        console.logAddress(inscAddr);
        vm.stopPrank();
        
        // alice mint in V2
        vm.deal(alice, 100 ether);
        uint256 aliceEthBefore = alice.balance;

        data = abi.encodeWithSignature("mintInscription(address)", inscAddr);
        vm.prank(alice);
        (success,) = payable(proxyAddr).call{value: MINT_FEE}(data);
        require(success, "Proxy call to mintInscription failed");
        assertEq(Inscription(inscAddr).balanceOf(alice), AMOUNT_PER_MINT);
         
        // check fee in admin
        uint256 ethBalanceNow = dev.balance;
        uint256 aliceEthNow = alice.balance;
        assertEq(aliceEthBefore - aliceEthNow, MINT_FEE);
        assertEq(ethBalanceNow - ethBalanceBefore, MINT_FEE);
    }
}
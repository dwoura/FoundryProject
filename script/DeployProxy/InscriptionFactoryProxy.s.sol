// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;
import "forge-std/Script.sol";
import "forge-std/console.sol";
import {Inscription} from "src/UpgradeableAndMinimalProxy/InscriptionFactory/Inscription.sol";
import {InscriptionFactoryLogicV1} from "src/UpgradeableAndMinimalProxy/InscriptionFactory/InscriptionFactoryLogicV1.sol";
import {InscriptionFactoryLogicV2} from "src/UpgradeableAndMinimalProxy/InscriptionFactory/InscriptionFactoryLogicV2.sol";
import {InscriptionFactoryProxy} from "src/UpgradeableAndMinimalProxy/InscriptionFactory/InscriptionFactoryProxy.sol";
import {ITransparentUpgradeableProxy,ProxyAdmin} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import {IInscriptionFactoryLogic} from "src/UpgradeableAndMinimalProxy/InscriptionFactory/IInscriptionFactoryLogic.sol";
bytes32 constant SALT1 = bytes32(
    uint256(0x00000000000002024210000000000000000000d3af2663da51c10215000000)
);
bytes32 constant SALT2 = bytes32(
    uint256(0x00000000000002024220000000000000000000d3af2663da51c10215000000)
);
bytes32 constant SALT3 = bytes32(
    uint256(0x00000000000002025230000000000000000000d3af2663da51c10215000000)
);
bytes32 constant SALT4 = bytes32(
    uint256(0x00000000000002025240000000000000000000d3af2663da51c10215000000)
);
uint256 constant MINT_FEE = 0.001 ether;
contract Deploy is Script {
    function run() public {
        uint256 devPvkey = vm.envUint("TEST_PRIVATE_KEY_1");
        address dev = vm.addr(devPvkey);
        uint256 userPvkey = vm.envUint("TEST_PRIVATE_KEY_2");
        address user = vm.addr(userPvkey);
        
        vm.createSelectFork("sepolia");
        //==== dev deploy
        vm.startBroadcast(devPvkey);
        InscriptionFactoryLogicV1 logicV1 = new InscriptionFactoryLogicV1{salt: SALT2}();
        InscriptionFactoryLogicV2 logicV2 = new InscriptionFactoryLogicV2{salt: SALT3}();
        InscriptionFactoryProxy proxy = new InscriptionFactoryProxy{salt: SALT4}(address(logicV1), dev,""); // new导入的合约，并携带构造参数
        address proxyAdminAddr = proxy.proxyAdmin(); // 管理员合约地址从 proxy 合约中获取
        ProxyAdmin proxyAdmin = ProxyAdmin(proxyAdminAddr);
        console2.log("logicV1 Deployed:", address(logicV1));
        console2.log("logicV2 Deployed:", address(logicV2));
        console2.log("proxy Deployed:", address(proxy));
        console2.log("proxyAdmin Deployed:", proxyAdminAddr);
        // V1 deploy by factory proxy contract
        IInscriptionFactoryLogic iproxy = IInscriptionFactoryLogic(address(proxy));
        iproxy.deployInscription("DwouraInsc", 21000000, 1000);
        address deployedV1Inscription = iproxy.getDeployedAddress(0);
        console2.log("inscriptionV1 Deployed:", deployedV1Inscription);
        vm.stopBroadcast();

        //==== V1 user mint
        vm.startBroadcast(userPvkey);
        iproxy.mintInscription(deployedV1Inscription);
        Inscription insc = Inscription(deployedV1Inscription);
        assert(insc.balanceOf(user) == 1000); 
        vm.stopBroadcast();

        //==== dev upgrade
        vm.startBroadcast(devPvkey);
        // upgradeTo V2
        // V2 initialize
        bytes memory data = abi.encodeWithSignature("initialize(address,uint256)", deployedV1Inscription, MINT_FEE);
        proxyAdmin.upgradeAndCall(ITransparentUpgradeableProxy(address(proxy)), address(logicV2), data);
        
        // V2 insc clone deploy
        iproxy.deployInscription("DwouraInsc", 21000000, 1000);
        address deployedV2Inscription = iproxy.getDeployedAddress(1);
        console2.log("inscriptionV2 Deployed:", deployedV2Inscription);
        vm.stopBroadcast();

        //==== V2 user mint with fee
        uint256 ethBefore = dev.balance;
        vm.startBroadcast(userPvkey);
        iproxy.mintInscription{value: MINT_FEE}(deployedV2Inscription); // mint new inscription
        vm.stopBroadcast();
        Inscription inscV2 = Inscription(deployedV2Inscription);
        assert(inscV2.balanceOf(user) == 1000);
        uint256 ethNow = dev.balance;
        assert(ethNow - ethBefore == MINT_FEE);
    }
}
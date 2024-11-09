// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;
import "forge-std/Script.sol";
import "forge-std/console.sol";
import {Upgrades} from "openzeppelin-foundry-upgrades/Upgrades.sol";
import {NFTMarketLogicV1} from "src/UpgradeableAndMinimalProxy/NFTMarket/NFTMarketLogicV1.sol";
import {NFTMarketLogicV2} from "src/UpgradeableAndMinimalProxy/NFTMarket/NFTMarketLogicV2.sol";
import {MyERC721} from "src/NFTMarket/ERC721.sol";
import {MessageHashUtils} from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";
import {MyPermitToken} from "src/PermitWhitelist/MyPermitToken.sol";
bytes32 constant SALT1 = bytes32(
    uint256(0x00000000000002024610000000000000000000d3af2663da51c10215000000)
);
bytes32 constant SALT2 = bytes32(
    uint256(0x00000000000002024620000000000000000000d3af2663da51c10215000000)
);
bytes32 constant SALT3 = bytes32(
    uint256(0x00000000000002025630000000000000000000d3af2663da51c10215000000)
);
bytes32 constant SALT4 = bytes32(
    uint256(0x00000000000002025640000000000000000000d3af2663da51c10215000000)
);
uint256 constant MINT_FEE = 0.001 ether;
contract Deploy is Script {
    function run() public {
        uint256 devPvkey = vm.envUint("TEST_PRIVATE_KEY_1");
        address dev = vm.addr(devPvkey);
        // uint256 buyerPvkey = vm.envUint("TEST_PRIVATE_KEY_2");
        // address buyer = vm.addr(buyerPvkey);
        
        vm.createSelectFork("sepolia");
        //==== dev deploy and upgrade by openzeppelin upgrades plugged
        vm.startBroadcast(devPvkey);
        // NFTMarketLogicV1 logicV1 = new NFTMarketLogicV1{salt: SALT1}();
        // NFTMarketLogicV2 logicV2 = new NFTMarketLogicV2{salt: SALT2}();
        MyPermitToken erc20 = new MyPermitToken{salt: SALT3}(dev);
        MyERC721 nft = new MyERC721{salt: SALT4}();

        // deploy proxy
        bytes memory data = abi.encodeWithSignature("initialize()");
        address proxyAddress = Upgrades.deployTransparentProxy("NFTMarketLogicV1.sol:NFTMarketLogicV1",dev,data);
        // get V1 Addr
        address logicV1Addr = Upgrades.getImplementationAddress(proxyAddress);

        //==== upgrade to v2
        data = abi.encodeWithSignature("initialize()");
        Upgrades.upgradeProxy(
            proxyAddress,
            "NFTMarketLogicV2.sol:NFTMarketLogicV2",
            data
        );
        // get V2 Addr
        address logicV2Addr = Upgrades.getImplementationAddress(proxyAddress);
        vm.stopBroadcast();

        console.log("dev addr:", dev);
        console.log("proxy addr:", proxyAddress);
        console.log("erc20 addr:", address(erc20));
        console.log("nft addr:", address(nft));
        console.log("v1 addr:", logicV1Addr);
        console.log("v2 addr:", logicV2Addr);
    }
}
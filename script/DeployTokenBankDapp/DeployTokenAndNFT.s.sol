// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;
import "forge-std/Script.sol";
import "forge-std/console.sol";
//import "@openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {MyPermitToken} from "src/PermitWhitelist/MyPermitToken.sol";
import {MyERC721} from "src/NFTMarket/ERC721.sol";

bytes32 constant SALT1 = bytes32(
    uint256(0x00000000000002024010000000000000000000d3af2663da51c10215000000)
);
bytes32 constant SALT2 = bytes32(
    uint256(0x00000000000002025010000000000000000000d3af2663da51c10215000000)
);

contract Deploy is Script {
    function run() public {
        vm.createSelectFork("anvil");

        // dev deploy
        vm.startBroadcast();
        address owner = address(0xEe44CF3ad948F4edD816E26582b7d6cB910e0901);
        MyPermitToken myErc20 = new MyPermitToken{salt: SALT1}(owner);
        MyERC721 myERC721 = new MyERC721{salt: SALT2}(); // new导入的合约，并携带构造参数
        console2.log("myErc20 Deployed:", address(myErc20));
        console2.log("myERC721 Deployed:", address(myERC721));
    
        console2.log(address(this));

        vm.stopBroadcast();
    }
}

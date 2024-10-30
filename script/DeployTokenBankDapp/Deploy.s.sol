// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "forge-std/Script.sol";
import "forge-std/console.sol";
//import "@openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {TokenBankV2} from "src/TokenBankV2/TokenBankV2.sol";
import {MyPermitToken} from "src/PermitWhitelist/MyPermitToken.sol";

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
        TokenBankV2 tokenBankV2 = new TokenBankV2{salt: SALT2}(owner,address(myErc20)); // new导入的合约，并携带构造参数
        console2.log("myErc20 Deployed:", address(myErc20));
        console2.log("tokenBankV2 Deployed:", address(tokenBankV2));
        
        address addr = tokenBankV2.owner();
        console2.log(addr);
        console2.log(address(this));
        tokenBankV2.init(address(0x000000000022D473030F116dDEE9F6B43aC78BA3)); // 初始化permit2合约

        vm.stopBroadcast();
    }
}

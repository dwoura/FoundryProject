// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "forge-std/Script.sol";
import "forge-std/console.sol";
//import "@openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {MyToken} from "src/DeployLearning/ERC20.sol";

bytes32 constant SALT = bytes32(uint256(0x000000000000020123000000000000000000000d3af2663da51c10215000000));
contract Deploy is Script {
    function run() public returns(MyToken myToken) {
        //vm.createSelectFork("sepolia");
        vm.startBroadcast();
        myToken = new MyToken{salt: SALT}("Dwoura","Dw"); // new导入的合约，并携带构造参数
        console2.log("MyToken Deployed:", address(myToken));
        vm.stopBroadcast();
    }
}


// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "forge-std/Script.sol";
import "forge-std/console.sol";
//import "@openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {MyToken} from "src/DeployLearning/ERC20.sol";
contract Deploy is Script {
    function run() external {
        //vm.createSelectFork("sepolia");
        vm.startBroadcast();
        new MyToken("Dwoura","Dw"); // new导入的合约，并携带构造参数
        vm.stopBroadcast();
    }
}


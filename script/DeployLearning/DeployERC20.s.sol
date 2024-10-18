// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "forge-std/console.sol";
//import "@openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {MyToken} from "src/DeployLearning/ERC20.sol";
contract Deploy is Script {
    function run() external {
        // 读取私钥文件
        string memory privateKey = vm.readFile("/Users/dwoura/.foundry/keystores/tester");
        
        // 用私钥广播交易
        vm.startBroadcast(privateKey);
        new MyToken("Dwoura","Dw"); // new导入的合约，并携带构造参数
        vm.stopBroadcast();
    }
}


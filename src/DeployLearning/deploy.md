# 使用 Foundry 命令和脚本，快速部署与开源一个合约
# cast命令初步使用
cast 与 forge 不同，是用于与以太坊合约进行交互的工具。  
而 forge 侧重于合约的开发和测试，两者配合使用。
## 常用钱包命令
+ `cast wallet -h` 查看帮助
+ `cast wallet new/new-mnemonic` 生成一个私钥或助记词
+ `cast wallet import` 导入私钥到内置 keystore 中，后续可以通过 --account参数来引用
# 部署和开源
## 部署
一般有两种方式，可以通过命令 `forge create` 或 `forge script` 来部署，但后者需要编写脚本。
+ `forge create`  
通过 `路径:合约名` 的形式找到需要部署的合约  
`forge create src/MyContract.sol:MyContract --private-key 私钥 --rpc-url xxx`   
若部署的合约需要携带构造函数参数，可在其后面添加`--constructor-args xxx xxx`来输入参数。  
`forge create src/MyContract.sol:MyContract --constructor-args xxx --private-key 私钥 --rpc-url xxx`   
也可以使用 --account 来替换私钥参数
`forge create src/MyContract.sol:MyContract --account xxx --rpc-url xxx`   
如果需要简化输入合约的路径，也可以在 remappings 中添加一个键值对做个映射。
+ `forge script`  
在脚本合约中，我们通过`new`合约的方式来创建（部署）一个合约实例，  
完整脚本如下：
```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "forge-std/Script.sol";
import "forge-std/console.sol";
//import "@openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {MyToken} from "src/DeployLearning/ERC20.sol";
contract Deploy is Script {
    function run() external {
        vm.startBroadcast(key);
        new MyToken("Dwoura","Dw"); // new导入的合约，并携带构造参数
        vm.stopBroadcast();
    }
}
```

`forge script script/MyContract.s.sol --account tester --rpc-url http://127.0.0.1:8545 --broadcast --verify -vvvv`  
--broadcast: 在部署完成后，自动广播交易。   
--verify: 部署后验证合约，包括检查合约地址是否有效。  
-vvvv: 输出详细的调试信息  

## 开源
+ 部署的同时开源  
我们只需要在命令中添加 `--verify` 参数即可。对于`forge create`， 会自动使用env中的`ETHERSCAN_API_KEY`参数；  
而对于 `forge script` 则是使用到了`forge.toml` 文件中的 `[rpc-endpoints]`下的自定义变量。
+ 部署完成后开源  
使用 `forge verify-contract 合约地址 合约路径:合约名 --chain 链名`。  
**若要为带有构造函数参数的合约开源**，需要注意使用参数`--constructor-args`，**参数用到构造函数的字节码**。  
假设我们有一个合约如下
```solidity
// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
contract MyToken is ERC20 { 
    constructor(string memory name_, string memory symbol_) ERC20(name_, symbol_) {
        _mint(msg.sender, 1e10*1e18);
    } 
}
```  
我们可以通过`cast abi-encode(constructor(string memory name_, string memory symbol_)) xxx xxx` 来获取字节码，其中的 xxx 是已部署合约的两个函数参数。  
`forge verify-contract 合约地址 合约路径:合约名 --chain 链名 --constructor-args 生成的字节码`。  
或者在cast的时候输出到一个文件中`> data.txt`，改为使用参数 `--constructor-args-path data.txt`。
## 一些注意事项
+ 使用 `--account` 参数，通过 keyStore 可以避免使用明文私钥，保证安全性。
+ 脚本的`vm.broadcast` 与命令中的`--broadcast`不一样，前者是模拟广播交易，而**后者才是实际在链上广播交易**。  
+ **建议每次运行前运行 forge clean命令，清除缓存**  
`ERROR foundry_compilers_artifacts_solc::sources: error=`的错误就是因为缓存问题引起的。
+ `forge create`的--rpc-url 是通过读 .env 文件中的`ETH_RPC_URL`，而 forge script 的--rpc-url 需要 `foundry.toml` 文件中的`rpc_endpoints`下自定义的rpc-url变量。  
可见，通过`forge script`的方式进行部署，可以很方便地选择定义好的rpc网络，而不需要反复地在`ETH_RPC_URL` 设置值rpc地址。
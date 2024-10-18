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
+ forge create  
通过 `路径:合约名` 的形式找到需要部署的合约  
`forge create src/MyContract.sol:MyContract --private-key 私钥 --rpc-url xxx`   
若部署的合约需要携带构造函数参数，可在其后面添加`--constructor-args xxx xxx`来输入参数。  
`forge create src/MyContract.sol:MyContract --constructor-args xxx --private-key 私钥 --rpc-url xxx`   
也可以使用 --account 来替换私钥参数
`forge create src/MyContract.sol:MyContract --account xxx --rpc-url xxx`   
如果需要简化输入合约的路径，也可以在 remappings 中添加一个键值对做个映射。
+ forge script  
在脚本合约中，我们通过`new`合约的方式来创建（部署）一个合约实例：  
`IERC20 `

## 开源

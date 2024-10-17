// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {BaseERC20} from "./ERC20.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "./ITokenReceiver.sol";

contract ERC20Hook is BaseERC20, ERC165{
    // 接口ID，用于注册
    bytes4 private constant tokenReceiverInterfaceId = type(ITokenReceiver).interfaceId;

    constructor(){
    }

    // 旧版注册方式已经移除，现改用重写supportsInterface方法。
    // 重写 supportsInterface 方法来对外展暴露本协议支持 ITokenReceiver 的接口。
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == tokenReceiverInterfaceId;
    }

    // 带钩子函数的转账
    function transferWithCallback(address _to,uint _amount,bytes memory data) public returns(bool){
        bool success;
        success = transfer(_to, _amount);
        require(success, "failed to transfer token");
        if(!isContract(_to)){
            // 不是合约地址则直接返回真，表示普通转账
            return true;
        }
        // 若为合约地址，转账后调用其tokensReceived()方法
        success = ITokenReceiver(_to).tokensReceived(msg.sender,msg.sender,_amount,data);
        require(success, "failed to call tokensReceived()");
        return true;
    }

    function isContract(address _addr) internal view returns(bool){
        return _addr.code.length != 0;
    }
}

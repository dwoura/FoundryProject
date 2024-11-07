// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ITransparentUpgradeableProxy,TransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
contract InscriptionFactoryProxy is TransparentUpgradeableProxy{
    address[] public inscriptionAddresses; // slot0 inscriptionAddresses
    // slot1 inscriptionTemplate
    constructor(address _logic, address _initialOwner, bytes memory _data) TransparentUpgradeableProxy(_logic,_initialOwner,_data) payable{

    }

    receive() external payable{}

    function proxyAdmin() public view returns(address){
        return _proxyAdmin();
    }

    // 调用父合约中的_fallback 函数，检查是否为管理员调用。
    // 若为管理员调用，则只能调用升级合约的函数；
    // 若是用户调用，则再调用父合约的_fallback()函数，最终执行代理调用。
}
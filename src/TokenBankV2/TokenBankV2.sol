// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;


import "./IERC20.sol";
import "./TokenBank.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "./ITokenReceiver.sol";

contract TokenBankV2 is TokenBank,ITokenReceiver {
    // 限定只能存取某种代币
    address _supportedToken;
    constructor(address supportedToken_) {
        _supportedToken = supportedToken_;
    }
    // 代币转账到合约后触发该函数，使得合约能够记账。省去了用户 approve 和 deposit 的操作
    function tokensReceived(address, address from, uint value, bytes calldata) public returns(bool){
        require(msg.sender == _supportedToken, "not a supported token");
        //(address token) = abi.decode(data,(address));
        updateUserInfo(from, IERC20(msg.sender), value);
        return true;
    }
}

// 若希望bank里能存取不同协议的代币，使用 erc165

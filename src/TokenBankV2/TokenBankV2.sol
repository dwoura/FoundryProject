// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;


import "./IERC20.sol";
import "./TokenBank.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "./ITokenReceiver.sol";
import {IERC20Permit} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Permit.sol";

contract TokenBankV2 is TokenBank,ITokenReceiver {
    // 限定只能存取某种代币
    address public _supportedToken; // 未来优化为数组
    constructor(address supportedToken_) {
        _supportedToken = supportedToken_;
    }

    function tokensReceived(address, address from, uint value, bytes calldata) public returns(bool){
        require(msg.sender == _supportedToken, "not a supported token");
        //(address token) = abi.decode(data,(address));
        updateUserInfo(from, IERC20(msg.sender), value);
        return true;
    }

    function setSupportedToken(address supportedToken_) public OnlyOwner{
        _supportedToken = supportedToken_;
    }



    struct Permit {
        address owner;
        address spender;
        uint256 value;
        uint256 nonce;
        uint256 deadline;
    }

    // Business scenario (data can be assumed in tests)
    // 1. Generate signature from users
    // User can input args: spender,value,deadline on dapp which use something like ethers.js to build eip712 typed structed data
    // and call method eth_signTypedData_v4 then request user to sign on Metamask.
    // 2. Users confirm their signature
    // Metamask returns signature data v,r,s for dapp after users confirmed
    // 3. Call func permitDeposit
    // Dapp carry the v,r,s data and other args to call permitDeposit function
    // 4. Contract and asset verification
    // TokenBank call permit from IERC20Permit to verify signature effectiveness, and then call transferFrom.
    //
    // user signature -> build typed structed data -> v,r,s data -> call permit -> transferFrom
    function permitDeposit(address depositor, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) public {
        IERC20Permit tokenPermit = IERC20Permit(_supportedToken);
        tokenPermit.permit(depositor, address(this), value, deadline, v, r, s); // do approve

        deposit(depositor, IERC20(address(tokenPermit)), value);
        emit Deposit(depositor, value);
    }
}

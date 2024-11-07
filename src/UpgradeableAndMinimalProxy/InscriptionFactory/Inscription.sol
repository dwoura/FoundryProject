// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Inscription is IERC20, ERC20{
    address public _proxyAddr;
    uint256 public _inscriptionSupply;
    uint256 public _perMint;
    
    string public _name;
    string public _symbol;

    bool public initialized;

    constructor() ERC20("","") {

    }

    modifier OnlyInitialized{
        require(initialized == true, "you need to initialize first");
        _;
    }

    function initialize(string memory symbol_, uint256 totalSupply_, uint256 perMint_, address proxyAddr_) public {
        require(!initialized,"insciption has been initialized");

        // (bool success, bytes memory data) = address(this).call(abi.encodeWithSignature("_proxyAdmin()"));
        // require(success, "failed to call _proxyAdmin");
        // (address adminAddr) = abi.decode(data,(address));
        // require(msg.sender == adminAddr, "only owner can do this");

        initialized = true;

        _proxyAddr = proxyAddr_;

        _name = symbol_;
        _symbol = symbol_;

        _inscriptionSupply = totalSupply_;
        _perMint = perMint_;
    }

    function mint(address to) public payable OnlyInitialized {
        // 代理调用，调用者依旧是外部账户
        require(msg.sender == _proxyAddr, "can only mint by proxy");
        require(totalSupply() + _perMint <= _inscriptionSupply, "minting completed");
        _mint(to, _perMint);
    }

    // function withdrawFee() public{
    //     require(address(this).balance > 0, "no any eth to withdraw");
    //     // 合约内 call 合约中另一个函数，msgsender 不会改变，依然是外部调用者，因为上下文没变。
    //     (bool success, bytes32 memory data) = address(this).call(abi.encodeWithSignature("_proxyAdmin()"));

    //     require(success, "failed to call _proxyAdmin");
    //     (address admin) = abi.decode(data,(address));

    //     require(msg.sender == admin, "only admin can withdraw fee"); // delegate call时msgsender是proxy 中的上下文

    //     admin.call{value: address(this).balance}("");
    // }
}
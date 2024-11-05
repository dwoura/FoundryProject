// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "./ITokenReceiver.sol";
import {ERC20Permit} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract MyPermitToken is IERC20, ERC20Permit{


    // the data in eip712  or using _hashTypedDataV4 in eip712.sol
    struct EIP712Domain {
        string name;
        string version;
        uint256 chainId;
        address verifyingContract;
    }
    bytes32 PERMIT_TYPEHASH = keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    bytes32 constant EIP712DOMAIN_TYPEHASH = keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");

    struct Permit {
        address owner;
        address spender;
        uint256 value;
        uint256 nonce;
        uint256 deadline;
    }

    constructor(address receiver) ERC20("DwouraPermit","DwPmt") ERC20Permit("DwouraPermit"){
        _mint(receiver, 1e18 ether);
    }

    // inherent DOMAIN_SEPARATOR() could be used.

    // aborted: new func is trasnferWithPermit
    // function transferWithSignature(
    //     address from,
    //     address to,
    //     uint256 amount,
    //     uint256 nonce,
    //     uint256 deadline,
    //     uint8 v,
    //     bytes32 r,
    //     bytes32 s
    //     ) public {
    //     require(block.timestamp <= deadline, "expired");
    //     require(_nonces[from] == nonce, "invalid nonce");
    //     _nonces[from]++;

    //     bytes32 hash = keccak256(abi.encodePacked(from, to, amount, nonce, deadline));
    //     address signer = ecrecover(hash, v, r, s);
    //     require(signer == from, "Invalid signature");
    //     _transfer(from, to, amount);
    // }

    // eip712 structed data, to improve func transferWithSignature above
    // function trasnferWithPermit(Permit calldata data, uint8 v, bytes32 r, bytes32 s) public {
    //     require(block.timestamp <= data.deadline, "expired");
    //     require(nonces[data.owner] == data.nonce, "invalid nonce");
    //     nonces[data.owner]++;

    //     // standardize data with eip712
    //     bytes32 digest = keccak256(
    //         abi.encodePacked(
    //             "\x19\x01", 
    //             DOMAIN_SEPARATOR,
    //             _hashStruct(data)
    //         )
    //     );
    //     require(ecrecover(digest, v, r, s) == data.owner, "invalid signature"); // verify data by ecrecovering the public address from v,r,s
    //     _transfer(data.owner, data.spender, data.value);
    // }

    function getPermitTypehash() public view returns(bytes32){
        return PERMIT_TYPEHASH;
    }

    function transferWithCallback(address _to,uint _amount,bytes memory data) public returns(bool){
        bool success;
        success = transfer(_to, _amount);
        require(success, "failed to transfer token");
        if(!isContract(_to)){
            return true;
        }

        success = ITokenReceiver(_to).tokensReceived(msg.sender,msg.sender,_amount,data);
        require(success, "failed to call tokensReceived()");
        return true;
    }

    function isContract(address _addr) internal view returns(bool){
        return _addr.code.length != 0;
    }

    function burn(address from, uint256 amount) public {
        _burn(from, amount);
    }
}

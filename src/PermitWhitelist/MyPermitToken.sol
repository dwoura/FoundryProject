// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "./ITokenReceiver.sol";
import {ERC20Permit} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract MyPermitToken is IERC20, ERC20Permit{

    // eip712 necessary
    struct EIP712Domain {
        string name;
        string version;
        uint256 chainId;
        address verifyingContract;
    }
    bytes32 PERMIT_TYPEHASH = keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    bytes32 constant EIP712DOMAIN_TYPEHASH = keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");
    bytes32 public override DOMAIN_SEPARATOR;

    struct Permit {
        address owner;
        address spender;
        uint256 value;
        uint256 nonce;
        uint256 deadline;
    }

    constructor() ERC20("DwouraPermit","DwPmt") ERC20Permit("DwouraPermit"){
        _mint(msg.sender, 1000000000000);

        // eip712: setup DOMAIN_SEPARATOR
        DOMAIN_SEPARATOR = _hashStruct(
            EIP712Domain({name: "DwouraPermit", version: "1", chainId: block.chainid, verifyingContract: address(this)}) // !! this is struct instantiation for type EIP712Domain
        );
    }

    // this func could be overload by multi same name 
    function _hashStruct(EIP712Domain memory eip712Domain) internal pure returns(bytes32){
        // to pack the format required by EIP712 struct
        return keccak256(
            abi.encode(
            EIP712DOMAIN_TYPEHASH,
            keccak256(bytes(eip712Domain.name)),
            keccak256(bytes(eip712Domain.version)),
            eip712Domain.chainId,
            eip712Domain.verifyingContract
            )
        );
    }

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
}

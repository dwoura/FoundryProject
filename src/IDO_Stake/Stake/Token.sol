// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {ERC20Permit,ERC20} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import {MyPermitToken} from "src/PermitWhitelist/MyPermitToken.sol";
import {StakePool} from "./StakePool.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {Test, console} from "forge-std/Test.sol";
contract Token is ERC20Permit{

    StakePool stakePool;
    MyPermitToken underlyingToken;

    struct LockInfo{
        address user;
        uint256 amount;
        uint256 lockTime;
        bool isBurnt;
    }
    mapping (address=>LockInfo[]) public locks;

    constructor(address stakePool_,address underlyingToken_)ERC20Permit("esRNT")ERC20("esRNT","esRNT"){
        stakePool = StakePool(stakePool_);
        underlyingToken = MyPermitToken(underlyingToken_);
    }

    function mint(address to, uint256 amount) public returns(uint256 id){
        require(msg.sender == address(stakePool), "only stake pool can mint tokens");
        underlyingToken.transferFrom(msg.sender,  address(this), amount); // from stake pool to this contract
        _mint(to, amount);

        // LockInfo[] locks = locksMap[to];
        // uint lastIndex;
        // if(locks.length == 0){
        //     lastIndex = 0;
        // }else{
        //     lastIndex = locks.length - 1;
        // }
        
        // claim 后同步锁仓信息，claim中，mint esRNT 给用户作为凭证，然后把RNT从质押池 转到 esRNT 中进行锁仓，并记录锁仓额度。
        // 锁仓概念：产出收益时不算锁仓，只有用户 claim 出 esRNT 后，才开始进行锁仓计算
        LockInfo memory lockInfo = LockInfo({
            user: to,
            amount: amount,
            lockTime: block.timestamp,
            isBurnt: false
        });
        locks[to].push(lockInfo);
        
        id = locks[to].length - 1;
    }

    // who burn? user
    // web check locks and call this function
    function burn(address user,uint256 id) public {
        require(msg.sender == address(stakePool), "only stake pool can mint tokens");
        require(id < locks[user].length, "invalid lock id");
        LockInfo storage lock = locks[user][id];
        require(!lock.isBurnt,"this id of lock has been burnt");
        lock.isBurnt = true;
        // burn esRNT
        _burn(user, lock.amount);
        // transfer unlocked RNT and burn locked RNT
        uint unlocked = Math.ceilDiv(lock.amount * (block.timestamp - lock.lockTime) * 1e10, 30 days) / 1e10;
        underlyingToken.transfer(lock.user, unlocked);
        underlyingToken.burn(address(this), lock.amount - unlocked); // burned the remaining tokens
    }

    // override transfer
    function transfer(address to, uint256 value) public override returns (bool) {
        // todo: require
        address owner = _msgSender();
        _transfer(owner, to, value);
        return true;
    }
}
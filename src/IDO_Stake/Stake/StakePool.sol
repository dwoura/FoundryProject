// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;
import {Token} from "./Token.sol";
import {IStakePool} from "./IStakePool.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {MyPermitToken} from "src/PermitWhitelist/MyPermitToken.sol";
import {Test, console} from "forge-std/Test.sol";
contract StakePool is IStakePool{
    //StakeInfo[] stakeInfos;
    Token rewardToken;
    MyPermitToken underlyingToken;
    uint256 rewardPerDay; // X times the amount in esRNT
    mapping(address=>StakeInfo) public stakeInfos;

    address public owner;
    constructor(){
        owner = msg.sender;
    }
    
    function init(address underlyingToken_,address rewardToken_, uint256 rewardPerDay_)public{
        require(msg.sender == owner, "only owner can do this");
        underlyingToken = MyPermitToken(underlyingToken_);
        rewardToken = Token(rewardToken_);
        rewardPerDay = rewardPerDay_;
        underlyingToken.approve(address(rewardToken), type(uint256).max);
    }

    function stake(uint amount) external{
        require(underlyingToken.allowance(msg.sender, address(this)) >= amount,"allowance not enough");
        bool success = underlyingToken.transferFrom(msg.sender, address(this), amount);
        require(success, "failed to call transferFrom");
        
        StakeInfo storage lastInfo = stakeInfos[msg.sender];
        // convert from per day to per second rewards
        //uint256 rewardPerSecond = Math.ceilDiv(rewardPerDay * 1e10, 1 days) ;
        //console.logUint(rewardPerSecond);
        // settlement last stake profits
        // unclaimed + rewards in this turn
        //uint256 CanClaimable = lastInfo.unclaimed + lastInfo.staked * (block.timestamp - lastInfo.lastUpdateTime) * rewardPerSecond / 1e10;
        uint256 CanClaimable = lastInfo.unclaimed + lastInfo.staked * (block.timestamp - lastInfo.lastUpdateTime) / 1 days;
        // update info
        lastInfo.staked += amount;
        lastInfo.unclaimed = CanClaimable;
        lastInfo.lastUpdateTime = block.timestamp;
    }

    function updateStakeInfo(address user) external {
        _updateStakeInfo(user);
    }

    function _updateStakeInfo(address user) internal {
        StakeInfo storage lastInfo = stakeInfos[user];
        // convert from per day to per second rewards
        //uint256 rewardPerSecond = Math.ceilDiv(rewardPerDay * 1e10, 1 days);
        // settlement last stake profits
        // unclaimed + rewards in this turn
        // uint256 CanClaimable = lastInfo.unclaimed + lastInfo.staked * (block.timestamp - lastInfo.lastUpdateTime) * rewardPerSecond / 1e10;
        uint256 CanClaimable = lastInfo.unclaimed + lastInfo.staked * (block.timestamp - lastInfo.lastUpdateTime) / 1 days;
        // update info
        lastInfo.unclaimed = CanClaimable;
        lastInfo.lastUpdateTime = block.timestamp;
    }

    // function stake(uint256 amount, bytes signature) external{
        
    // }

    function unstake(uint256 amount) external returns(uint256){
        StakeInfo memory stakeInfo = stakeInfos[msg.sender];
        require(stakeInfo.staked > 0 && amount <= stakeInfo.staked, "staking token not enough");
       
        uint256 lockInfoId = _claim(msg.sender);
        
        // return staked
        require(underlyingToken.balanceOf(address(this)) >= amount,"InsufficientBalance");
        bool success = underlyingToken.transfer(msg.sender, amount);
        require(success, "failed to refund");

        delete stakeInfo;

        return lockInfoId;
        // locked token should be manually burn after unstake
    }

    // cliam rewards
    function claim() external returns(uint256){
        _updateStakeInfo(msg.sender);
        return _claim(msg.sender);
    }

    function _claim(address user) internal returns(uint256){
        StakeInfo memory stakeInfo = stakeInfos[user];
        //console.logUint(stakeInfo.unclaimed);
        require(stakeInfo.unclaimed > 0, "no claimable token");
        // 若用户有可以 claim的 RNT，需要从质押的奖励 RNT代币池中，由 esRNT 合约 transferFrom 到 esRNT 合约中锁仓，最后mint esRNT 凭证给用户。
        // 前提：项目方先分配好 RNT 到本质押池合约中。
        return rewardToken.mint(user, stakeInfo.unclaimed);
    }

    function withdrawUnlockedAndBurnLockedToken(uint256 id) external {
        rewardToken.burn(msg.sender, id);
    }
}
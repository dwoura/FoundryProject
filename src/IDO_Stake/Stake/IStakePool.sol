// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

interface IStakePool{
    struct StakeInfo{
        uint256 staked;
        uint256 unclaimed;
        uint256 lastUpdateTime;
    }
    
    function stake(uint256 amount) external ;
    //function stake(uint256 amount, bytes memory signature) external;
    function unstake(uint256 amount) external returns(uint256);
    function claim() external returns(uint256);
    function withdrawUnlockedAndBurnLockedToken(uint256 id) external;
}
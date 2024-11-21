// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;
import "src/Compound/IStaking.sol";
contract StakingPool{

    struct stakeInfo{
        bool staked;
        uint256 unClaimed;
        uint256 lastUpdateTime;
    }

    function stake() public {

    }

    function unstake() public {
        
    }

    function claim() public {
        
    }

    function balanceOf(address account) external view returns (uint256){

    }

    function earned(address account) external view returns (uint256){

    }
}
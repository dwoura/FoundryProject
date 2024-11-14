// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {IUniswapV2Pair} from "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol"
import {IDex} from "src/DexMechanism/IDex.sol";


contract MyDex{
    
    constructor(){

    }

    function sellETH(address buyToken,uint256 minBuyAmount) external payable {

    }

    function buyETH(address sellToken,uint256 sellAmount,uint256 minBuyAmount) external {

    } 
}
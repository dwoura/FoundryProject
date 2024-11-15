// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;
import {IDex} from "./IDex.sol";
import {IUniswapV2Pair} from "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import {IERC20} from "@uniswap/v2-core/contracts/interfaces/IERC20.sol";
import {IUniswapV2Router02} from "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import {IWETH} from "@uniswap/v2-periphery/contracts/interfaces/IWETH.sol";

contract MyDex{
    IUniswapV2Router02 public uniswapV2Router;
    IWETH public WETH;
    constructor(){
        uniswapV2Router = IUniswapV2Router02(address(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D));
        WETH = IWETH(address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2));
    }
    receive() external payable {}
    function sellETH(address buyToken) external payable{
        require(msg.value > 0, "eth balance not enough");
        address[] memory path = new address[](2);
        path[0] = address(WETH);
        path[1] = buyToken;

        // getAmountsOut
        uint[] memory amounts = uniswapV2Router.getAmountsOut(msg.value, path);
        uint amountOut = amounts[amounts.length - 1];

        uniswapV2Router.swapETHForExactTokens{value: msg.value}(amountOut, path, msg.sender, block.timestamp);
    }

    function buyETH(address sellToken,uint256 sellAmount,uint256 minBuyAmount) external {
        // build swap path
        address[] memory path = new address[](2);
        path[0] = sellToken;
        path[1] = address(WETH);
        // dex hold tokens and do swap
        IERC20(sellToken).transferFrom(msg.sender, address(this), sellAmount);
        IERC20(sellToken).approve(address(uniswapV2Router), sellAmount);
        uniswapV2Router.swapExactTokensForETH(sellAmount, minBuyAmount, path, msg.sender, block.timestamp);
    } 
}
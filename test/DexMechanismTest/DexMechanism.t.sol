// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Test, console} from "forge-std/Test.sol";
import {MyDex} from "src/DexMechanism/MyDex.sol";
import {MyPermitToken} from "src/PermitWhitelist/MyPermitToken.sol";
import {IUniswapV2Factory} from "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import {IUniswapV2Pair} from "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import {IUniswapV2Router02} from "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import {IWETH} from "@uniswap/v2-periphery/contracts/interfaces/IWETH.sol";
import {IERC20} from "@uniswap/v2-core/contracts/interfaces/IERC20.sol";
import {UniswapV2Library} from "@uniswap/v2-periphery/contracts/libraries/UniswapV2Library.sol";
// UniswapV2
contract MyDexTest is Test {
    MyDex myDex;

    MyPermitToken token;
    IWETH weth;
    address wethAddr;
    address tokenAddr;

    IUniswapV2Router02 router;
    IUniswapV2Factory factory;
    IUniswapV2Pair pair;

    address dev = address(0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266);
    address alice = address(0x70997970C51812dc3A010C7d01b50e0d17dc79C8);

    uint amountADesired;
    uint amountBDesired;
    uint amountAMin;
    uint amountBMin;
    address to;
    uint deadline;

    // address UNISWAP_V2_ROUTER_ADDRESS =
    //     0x7a250d5630B4cF539739df2C5dAcb4c659F2488D; // Mainnet
    function setUp() public {
        myDex = new MyDex();
        token = new MyPermitToken(dev);
        tokenAddr = address(token);
        weth = IWETH(address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2));
        wethAddr = address(weth);
        factory = IUniswapV2Factory(
            address(0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f)
        );
        pair = IUniswapV2Pair(factory.createPair(wethAddr, tokenAddr));
        router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    }

    function test_AddLiquidity() public {
        (uint amountWETH, uint amountToken, uint liquidity) = _addLiquildity();

        // Check liquidity
        (uint reserveToken, uint reserveWETH) = UniswapV2Library.getReserves(
            address(factory),
            tokenAddr,
            wethAddr
        );

        assertEq(reserveToken, 1000 ether);
        assertEq(reserveToken, amountToken);
        assertEq(reserveWETH, 10 ether);
        assertEq(reserveWETH, amountWETH);
        assertEq(liquidity, 100 ether - 1000);
    }

    function _addLiquildity()
        internal
        returns (uint amountA, uint amountB, uint liquidity)
    {
        // eth/token
        // Approve tokens
        vm.startPrank(dev);
        weth.deposit{value: 20 ether}();
        token.approve(address(router), 1000 ether);
        IERC20(wethAddr).approve(address(router), 10 ether);

        // Add liquidity
        (amountA, amountB, liquidity) = router.addLiquidity(
            wethAddr,
            tokenAddr,
            10 ether,
            1000 ether,
            0,
            0,
            dev,
            block.timestamp
        );
        vm.stopPrank();
    }

    function test_RemoveLiquidity() public {
        // dev add
        _addLiquildity();

        address pairAddr = UniswapV2Library.pairFor(
            address(factory),
            wethAddr,
            tokenAddr
        );
        // Get LP tokens
        IERC20 lpToken = IERC20(pairAddr);
        uint lpBalance = lpToken.balanceOf(dev);

        vm.startPrank(dev);
        lpToken.approve(address(router), lpBalance);
        // Remove liquidity
        router.removeLiquidity(
            tokenAddr,
            wethAddr,
            lpBalance,
            0,
            0,
            dev,
            block.timestamp
        );
        vm.stopPrank();

        // Check liquidity
        (uint reserveWETH, uint reserveToken) = UniswapV2Library.getReserves(
            address(factory),
            wethAddr,
            tokenAddr
        );
        assertTrue(reserveToken == 10000);
        assertTrue(reserveWETH == 100);
        assertEq(IUniswapV2Pair(pairAddr).totalSupply(), 1000);
    }

    function test_SellETH() public {
        // Dev Add Liquidity
        _addLiquildity();

        uint256 tokenBalanceBefore = token.balanceOf(dev);
        console.log("tokenBalanceBefore:", tokenBalanceBefore);

        address[] memory path = new address[](2);
        path[0] = address(wethAddr);
        path[1] = address(tokenAddr);
        // amounts[0] => ETH, amounts[1] => Token
        uint256[] memory amounts = router.getAmountsOut(1 ether, path);
        assertTrue(amounts[amounts.length - 1] > amounts[0]);
        uint256 expectedTokenAmountOut = amounts[amounts.length - 1];
        // sell ETH for token
        vm.prank(dev);
        myDex.sellETH{value: 1 ether}(tokenAddr);

        // Check if the balance of token has increased
        uint256 tokenBalanceBeforeAfter = token.balanceOf(dev);
        assertEq(
            tokenBalanceBeforeAfter,
            tokenBalanceBefore + expectedTokenAmountOut
        );
    }

    function test_BuyETH() public {
        _addLiquildity();
        // Approve and deposit tokens
        vm.startPrank(dev);
        uint256 buyETHAmount = 1 ether;
        token.approve(address(myDex), buyETHAmount);

        address[] memory path = new address[](2);
        path[0] = tokenAddr;
        path[1] = wethAddr;

        // amountOuts = [ ? RNT, ? WETH]
        uint[] memory amountOuts = router.getAmountsOut(
            buyETHAmount,
            path
        );

        // amounts[1] is WETH amountOut which should be greater than 0
        assertTrue(amountOuts[amountOuts.length - 1] > 0);

        // get balance before buy eth
        uint256 ethBalanceBefore = dev.balance;
        console.log("ethBalanceBefore:", ethBalanceBefore);

        // with slippage
        uint256 expectMinETH = (amountOuts[amountOuts.length - 1] * 99) / 100;
        // Buy ETH
        myDex.buyETH(tokenAddr,buyETHAmount, expectMinETH);

        // Check if the balance of the contract has increased
        uint256 ethBalanceAfter = dev.balance;
        console.log("ethBalanceAfter:", ethBalanceAfter);
        assertGe(ethBalanceAfter, ethBalanceBefore + expectMinETH);
        vm.stopPrank();
    }
}

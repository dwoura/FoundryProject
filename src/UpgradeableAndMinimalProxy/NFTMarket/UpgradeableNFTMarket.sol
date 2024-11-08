// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Upgrades} from "@openzeppelin/upgrades/src/Upgrades.sol";
contract NFTMarketProxy {

    constructor(){
        Upgrades.deployTransparentProxy()
    }
}
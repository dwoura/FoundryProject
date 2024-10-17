// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "./IERC20.sol";

interface IBank {
    function deposit(IERC20 token, uint amount) external payable;
    function withdraw(IERC20 token, uint amount) external payable;
}

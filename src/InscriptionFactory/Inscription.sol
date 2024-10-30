// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract MyInscription is IERC20, ERC20{

    uint _inscriptionSupply;
    uint _perMint;

    constructor(string memory symbol_, uint totalSupply_, uint perMint_) ERC20(symbol_,symbol_) {
        _inscriptionSupply = totalSupply_;
        _perMint = perMint_;
    }

    // _totalSupply means minted num currently
    function mint() public {
        require(totalSupply() + _perMint <= _inscriptionSupply, "minting completed");
        _mint(msg.sender, _perMint);
    }
}
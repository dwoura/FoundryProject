// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;
import {Inscription} from "./Inscription.sol";
contract InscriptionFactoryLogicV1{
    address[] public inscriptionAddresses;
    constructor() {
    }

    function deployInscription(string memory symbol, uint256 totalSupply, uint256 perMint) external{
        Inscription inscription = new Inscription();
        inscription.initialize(symbol, totalSupply, perMint,address(this));
        inscriptionAddresses.push(address(inscription));
    }

    function mintInscription(address tokenAddr) external{
        Inscription token = Inscription(tokenAddr);
        token.mint(msg.sender);
    }

    function getDeployedAddress(uint256 id) view external returns(address){
        return inscriptionAddresses[id];
    }
}
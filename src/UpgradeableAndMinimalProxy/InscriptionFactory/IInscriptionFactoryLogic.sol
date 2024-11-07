// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;
interface IInscriptionFactoryLogic{
    function deployInscription(string memory symbol, uint256 totalSupply, uint256 perMint) external;
    function mintInscription(address tokenAddr) external payable;
    function getDeployedAddress(uint256 id) view external returns(address);
}
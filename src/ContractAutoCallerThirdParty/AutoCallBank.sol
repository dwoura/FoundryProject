// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.26;

contract AutoCallBank{
    address payable public owner;
    address payable public keeper;
    uint256 public totalDeposits;
    uint256 public totalUpkeeps;
    uint256 public depositLimit;
    mapping(address => uint256) public balances;
    mapping(address => bool) public upkeeps;

    modifier onlyOwner {
        require(msg.sender == owner, "Only the owner can call this function");
        _;
    }
    modifier onlyKeeper() {
        require(msg.sender == keeper, "Not authorized keeper");
        _;
    }
    constructor(){
        owner = payable(msg.sender);
        depositLimit = 0.01 ether;
    }

    // check condition
    function checkUpkeep(bytes calldata checkData) external view returns (bool upkeepNeeded, bytes memory performData){
        return (address(this).balance >= depositLimit, "");
    }

    // do logic when condition is met
    function performUpkeep(bytes calldata perform) external{
        require(address(this).balance >= depositLimit, "No balance to perform upkeep");
        uint256 balance = (address(this).balance * 1e10 / 2) / 1e10;
        owner.call{value: balance}("");
    }
    
    function setKeeper(address payable keeper_) external onlyOwner{
        keeper = keeper_;
    }
    
    function deposit() external payable {
        balances[msg.sender] += msg.value;
    }

    function withdraw(uint256 amount) external payable{
        require(msg.sender == owner, "Only the owner can withdraw");
        require(balances[msg.sender] >= amount, "No balance to withdraw");
        balances[msg.sender] -= amount;
        address(msg.sender).call{value: amount}("");
    }

    function setDepositLimit(uint256 depositLimit_) external onlyOwner {
        depositLimit = depositLimit_;
    }

    function withdrawTotal() external onlyOwner {
        owner.call{value: address(this).balance}("");
    }
}

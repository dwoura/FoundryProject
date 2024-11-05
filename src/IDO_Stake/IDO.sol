// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract IDO{
    address owner;
    // presale token

    struct Offer{
        bool end; // manual set
        uint256 price;
        uint256 amount;
        uint256 softCap;
        uint256 totalETH;
        address fundraiser;
        bool isStart;
    }
    mapping(address => Offer) offerings; // token->offer
    mapping(address=>mapping(address=>uint256)) balances; // token->user->balance
    constructor(){
        owner = msg.sender;
    }

    modifier onlySuccess(address token){
        Offer storage offering = offerings[token];
        require(offering.isStart == false, "offering has exist");
        require(offering.end && offering.totalETH >= offering.softCap);
        _;
    }

    modifier onlyFailed(address token){
        Offer storage offering = offerings[token];
        require(offering.isStart == false, "offering has exist");
        require(offering.end && offering.totalETH < offering.softCap);
        _;
    }

    modifier onlyActive(address token){
        Offer storage offering = offerings[token];
        require(offering.isStart == false, "offering has exist");
        require(!offering.end && offering.totalETH + msg.value < offering.softCap * 2);
        _;
    }

    function newOffering(address targetToken,uint256 presalePrice, uint256 presaleAmount) public {
        Offer storage offering = offerings[targetToken];
        require(offering.isStart == false, "offering has exist");
        
        IERC20 token = IERC20(targetToken);
        // raiser can approve or transfer token directly
        uint256 allowance = token.allowance(msg.sender, address(this));
        uint256 balanceOfToken = token.balanceOf(address(this));
        require(allowance == presaleAmount || balanceOfToken == presaleAmount, "please approve or transfer the presaleAmount to contract");
        if(allowance == presaleAmount && balanceOfToken != presaleAmount){
            token.transferFrom(msg.sender, address(this), presaleAmount);
        } 

        require(balanceOfToken == presaleAmount,"balance of token is not enough");

        // new offering
        offerings[targetToken] = Offer({
            end: false,
            price: presalePrice,
            amount: presaleAmount,
            softCap: presalePrice * presaleAmount,
            totalETH: 0,
            fundraiser: msg.sender, // set fundraiser
            isStart: true
        });

    }

    function presale(address targetToken) public onlyActive(targetToken) payable {
        balances[targetToken][msg.sender] += msg.value;
    }

    function claim(address targetToken) public onlySuccess(targetToken) {
        Offer memory offering = offerings[targetToken];
        uint256 totalETH = offering.totalETH;
        uint256 claimAmount = offering.amount * balances[targetToken][msg.sender] / totalETH;

        balances[targetToken][msg.sender] = 0; // reset to zero
        IERC20 token = IERC20(targetToken);
        token.transfer(msg.sender,claimAmount);
    }

    function withdraw(address targetToken) public onlySuccess(targetToken) {
        Offer storage offering = offerings[targetToken];
        uint256 totalETH = offering.totalETH;
        uint256 toTeam = totalETH * 1 / 10; // tax for ido team when fundraiser withdrawal
        (bool success, ) = owner.call{value: toTeam}("");
        require(success, "call failed");
        success = false;
        
        uint toFundraiser = totalETH - toTeam;
        (success, ) = offering.fundraiser.call{value: toFundraiser}("");
        require(success, "call failed");
    }

    // estimate the amount you can claim
    function estAmount(address targetToken,uint256 eths) public view returns(uint256){
        Offer storage offering = offerings[targetToken];
        return offering.amount * eths / (offering.totalETH + eths);
    }

    function refund(address targetToken)public onlyFailed(targetToken) {
        (bool success, ) = address(msg.sender).call{value: balances[targetToken][msg.sender]}("");
        require(success, "call failed");

        balances[targetToken][msg.sender] = 0;
    }

    function setEnd(address targetToken,bool state) public{
        Offer storage offering = offerings[targetToken];
        require(owner == msg.sender,"only owner can do this");
        offering.end = state;
    }
}
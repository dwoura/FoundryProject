// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

contract Multisig{
    address[] public _owners;
    uint public _threshold;

    struct Proposal{
        uint id;
        address to;
        bytes data;
        uint value; // eth value to send
        uint confirmations; // total nums of confirmations
        bool isExecuted;
    }

    mapping(uint=>Proposal) public proposals;
    uint public proposalNums; // total nums


    modifier OnlyOwners{
        require(isExistInOwners(), "only owner can do this");
        _;
    }

    constructor(address[] memory owners_,uint threshold_){
        require(owners_.length > 0, "owners length must be greater than zero");
        require(threshold_ >0, "threshold must be greater than zero");

        _owners =  owners_;
        _threshold = threshold_;
    }

    function MakeProposal(address to, uint value, bytes memory data) public OnlyOwners{
        proposalNums++;
        Proposal memory proposal = Proposal(
            proposalNums,
            to,
            data,
            value,
            0,
            false
        );
        proposals[proposalNums] = proposal;
    }

    function confirmProposal(uint proposalId) public OnlyOwners payable {
        require(proposalId<=proposalNums, "can not confirm a proposal id greater than nums");
        Proposal storage proposal =  proposals[proposalId];

        require(proposal.isExecuted == false, "can not confirm a executed proposal"); 
        proposal.confirmations++;

        // exe when meet threshold
        if(proposal.confirmations >= _threshold){
            executeProposal(proposalId);
        }
    }

    function executeProposal(uint proposalId) internal{
        Proposal storage proposal =  proposals[proposalId];

        (bool success,) = proposal.to.call{value: proposal.value}(proposal.data);
        require(success,"failed to call target function");
        proposal.isExecuted = true;
    }

    function isExistInOwners() internal view returns(bool){
        for(uint i=0;i<_owners.length;i++){
            if(msg.sender == _owners[i]){
                return true;
            }
        }
        return false;
    }
}
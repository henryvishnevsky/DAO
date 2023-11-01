//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "./Token.sol";

contract DAO {
    address owner;
    Token public token;
    uint256 public quorum;

    struct Proposal {
        uint256 id;
        string name;
        uint256 amount;
        address payable recipient;
        uint256 votes;
        bool finalized;
    }

    uint256 public proposalCount;

    mapping(uint256 => Proposal) public proposals;
    mapping(address => mapping(uint256 => bool)) votes;

    event Propose(
        uint256 id,
        uint256 amount,
        address recipient,
        address creator
    );

    event Vote(
        uint256 id,
        address investor
    );

    event Finalize(
        uint256 id
    );

    constructor(Token _token, uint256 _quorum) {
        owner = msg.sender;
        token = _token;
        quorum = _quorum;
    }

    //allow contract to receive ether
    receive() external payable {}

    modifier onlyInvestor() {
        require(
            token.balanceOf(msg.sender) > 0,
            "The proposer must be token holder"
        );
        _;
    }

    //Proposals
    function createProposal(
        string memory _name,
        uint256 _amount,
        address payable _recipient
    ) external onlyInvestor {

        require(address(this).balance >= _amount);

        proposalCount++;

        proposals[proposalCount] = Proposal(
            proposalCount,
            _name,
            _amount,
            _recipient,
            0,
            false
        );

        emit Propose(proposalCount, _amount, _recipient, msg.sender);

    }

    function vote(uint256 _id) external onlyInvestor {
        //fetch proposal from mapping by id
        Proposal storage proposal = proposals[_id];

        //Check that the investor hasn't voted
        require(!votes[msg.sender][_id], "Already voted");

        //update votes
        proposal.votes += token.balanceOf(msg.sender);

        //Track that user has voted
        votes[msg.sender][_id] = true;

        //Emit an event
        emit Vote(_id, msg.sender);

    }

    function finalizeProposal(uint256 _id) external onlyInvestor {

        //Fetch proposal
        Proposal storage proposal = proposals[_id];

        //Ensure proposal is not already finalizied
        require(proposal.finalized == false, "Proposal already finalized"); 

        //Mark proposal finalized
        proposal.finalized = true;

        //check that proposal has anough votes
        require(proposal.votes >= quorum, "Quorum is not reached");

        //Check that the contract has enough ether
        require(address(this).balance >= proposal.amount);

        //transfer funds
        (bool sent, ) = proposal.recipient.call{value: proposal.amount}("");
        require(sent);

        //emit event
        emit Finalize(_id);

    }

}


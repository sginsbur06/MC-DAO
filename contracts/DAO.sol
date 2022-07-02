//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./DAOInterface.sol";
import "./Token.sol";


contract DAO is DAOInterface {

    // The minimum debate period that a proposal can have
    uint constant minProposalDebatePeriod = 15 days;

    // The minimum debate period that a split proposal can have
    uint constant quorumReducePeriod = 60 days;
    
    // Period after which a proposal is closed (in the case `executeProposal` fails because it throws)
    uint constant executeProposalPeriod = 10 days;

    // Token contract
    Token token;

    // Proposals to spend the DAO's ether
    Proposal[] public proposals;

    // The quorum needed for each proposal is partially calculated by totalSupply / minQuorumDiv
    uint public minQuorumDiv;

    // Address of the curator
    address public curator;

    // The list of addresses the DAO is allowed to send ether to
    mapping (address => bool) public allowedRecipients;

    // Mapping of addresses blocked during a vote (not allowed to transfer DAO tokens)
    mapping (address => uint) public blocked;

    // Mapping of addresses and proposal voted on by this address
    mapping (address => uint[]) public votingRegister;

    // The minimum deposit (in wei) required to submit any proposal
    uint public proposalDeposit;

    // The accumulated sum of all current proposal deposits
    uint sumOfProposalDeposits;



    constructor(
        address _curator,
        uint _proposalDeposit,
        Token _token
        ) {
        token = _token;
        curator = _curator;
        proposalDeposit = _proposalDeposit;
        minQuorumDiv = 5; // sets the minimal quorum to 20%


        allowedRecipients[address(this)] = true;
        allowedRecipients[curator] = true;
        proposals.push();
    }

    modifier onlyCurator {
        require(msg.sender == curator, "Not a curator");
        _;
    }

    modifier onlyTokenholders {
        require(token.balanceOf(msg.sender) != 0, "Not a tokenHolder");
        _;
    }

    function newProposal(
        address _recipient,
        uint _amount,
        string memory _description,
        bytes memory _transactionData,
        uint _debatingPeriod
    ) onlyTokenholders public payable returns (uint _proposalID) {

        require(allowedRecipients[_recipient]
            && _debatingPeriod > minProposalDebatePeriod
            && msg.value >= proposalDeposit
            && msg.sender != address(this), "Not correct proposal");


        _proposalID = proposals.length;

        Proposal storage p = proposals.push();
        p.recipient = _recipient;
        p.amount = _amount;
        p.description = _description;
        p.proposalHash = keccak256(abi.encode(_recipient, _amount, _transactionData));
        p.votingDeadline = block.timestamp + _debatingPeriod;
        p.open = true;
        //p.proposalPassed = False; 
        p.creator = msg.sender;
        p.proposalDeposit = msg.value;

        sumOfProposalDeposits += msg.value;

        emit ProposalAdded(
            _proposalID,
            _recipient,
            _amount,
            _description
        );
    }


    function checkProposalCode(
        uint _proposalID,
        address _recipient,
        uint _amount,
        bytes memory _transactionData
    ) public view returns (bool _codeChecksOut) {
        Proposal storage p = proposals[_proposalID];

        return p.proposalHash == keccak256(abi.encode(_recipient, _amount, _transactionData));
    }


    function vote(uint _proposalID, bool _supportsProposal) public {

        Proposal storage p = proposals[_proposalID];
        require(block.timestamp < p.votingDeadline, "Too late");

        unVote(_proposalID);

        if (_supportsProposal) {
            p.yes += token.balanceOf(msg.sender);
            p.votedYes[msg.sender] = true;
        } else {
            p.no += token.balanceOf(msg.sender);
            p.votedNo[msg.sender] = true;
        }

        if (blocked[msg.sender] == 0) {
            blocked[msg.sender] = _proposalID;
        } else if (p.votingDeadline > proposals[blocked[msg.sender]].votingDeadline) {
            blocked[msg.sender] = _proposalID;
        }

        votingRegister[msg.sender].push(_proposalID);
        emit Voted(_proposalID, _supportsProposal, msg.sender);
    }


    function unVote(uint _proposalID) public {
        Proposal storage p = proposals[_proposalID];
        require(block.timestamp < p.votingDeadline, "Too late");

        if (p.votedYes[msg.sender]) {
            p.yes -= token.balanceOf(msg.sender);
            p.votedYes[msg.sender] = false;
        }

        if (p.votedNo[msg.sender]) {
            p.no -= token.balanceOf(msg.sender);
            p.votedNo[msg.sender] = false;
        }
    }


    function unVoteAll() public {
        
        for (uint i = 0; i < votingRegister[msg.sender].length; i++) {
            Proposal storage p = proposals[votingRegister[msg.sender][i]];
            if (block.timestamp < p.votingDeadline)
                unVote(votingRegister[msg.sender][i]);
        }

        delete votingRegister[msg.sender];
        blocked[msg.sender] = 0;
    }


    function executeProposal(
        uint _proposalID,
        bytes memory _transactionData
    ) public onlyCurator returns (bool _success) {

        Proposal storage p = proposals[_proposalID];

        if (p.open && block.timestamp > p.votingDeadline + executeProposalPeriod) {
            closeProposal(_proposalID);
            return true;
        }

        require(block.timestamp >= p.votingDeadline
            && p.open
            && !p.proposalPassed
            && p.proposalHash == keccak256(abi.encode(p.recipient, p.amount, _transactionData)),
            "Proposal cannot be executed");


        if (!allowedRecipients[p.recipient]) {
            closeProposal(_proposalID);
            payable(p.creator).transfer(p.proposalDeposit);
            return true;
        }

        bool proposalCheck = true;

        uint quorum = p.yes;
              

        if (quorum >= minQuorum(p.amount)) {
            (bool success,) = p.creator.call{value: p.proposalDeposit}("");
            require(success, "Transaction failed");      
        }

        if (quorum >= minQuorum(p.amount) && p.yes > p.no && proposalCheck) {
            
            p.proposalPassed = true;

            (bool success,) = p.recipient.call{value: p.amount}(_transactionData);
            require(success, "Transaction failed");

            _success = true;
        }

        closeProposal(_proposalID);

        emit ProposalCounted(_proposalID, _success, quorum);
    }


    function closeProposal(uint _proposalID) internal {
        Proposal storage p = proposals[_proposalID];

        if (p.open) {
            sumOfProposalDeposits -= p.proposalDeposit;
        }
        p.open = false;
    }


    function changeProposalDeposit(uint _proposalDeposit) external onlyCurator {

        proposalDeposit = _proposalDeposit;
    }


    function changeAllowedRecipients(address _recipient, bool _allowed) external onlyCurator returns (bool _success) {
        allowedRecipients[_recipient] = _allowed;

        emit AllowedRecipientChanged(_recipient, _allowed);
        return true;
    }


    function actualBalance() public view returns(uint _actualBalance) {
        return address(this).balance - sumOfProposalDeposits;
    }


    function minQuorum(uint _value) internal view returns (uint _minQuorum) {
       
        return token.totalSupply() / minQuorumDiv +
            (_value * token.totalSupply()) / (3 * (actualBalance()));
    }


    function numberOfProposals() public view returns (uint _numberOfProposals) {
        
        return proposals.length - 1;
    }


    function changeOrGetBlocked(address _account) public returns (bool) {
        if (blocked[_account] == 0) {
            return false;
        }
        Proposal storage p = proposals[blocked[_account]];
        if (!p.open) {
            blocked[_account] = 0;
            return false;
        } else {
            return true;
        }
    }


    function unblockMyAcc() public returns (bool) {
        return changeOrGetBlocked(msg.sender);
    }


    receive() external payable {}

}
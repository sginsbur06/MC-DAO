//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


interface DAOInterface {
   
    struct Proposal {
        // The address where the `amount` will go to if the proposal is accepted
        address recipient;
        // The amount to transfer to `recipient` if the proposal is accepted.
        uint amount;
        // A text description of the proposal
        string description;
        // A unix timestamp, denoting the end of the voting period
        uint votingDeadline;
        // True if the proposal's votes have yet to be counted
        bool open;
        // the majority said yes
        bool proposalPassed;
        // A hash to check validity of a proposal
        bytes32 proposalHash;
        // Deposit the creator added when submitting their proposal
        uint proposalDeposit;
        // Number of Tokens in favor of the proposal
        uint yes;
        // Number of Tokens opposed to the proposal
        uint no;
        // Mapping to check if a shareholder has voted for it
        mapping (address => bool) votedYes;
        // Mapping to check if a shareholder has voted against it
        mapping (address => bool) votedNo;
        // Address of the shareholder who created the proposal
        address creator;
    }

   
    function newProposal(
        address _recipient,
        uint _amount,
        string memory _description,
        bytes memory _transactionData,
        uint _debatingPeriod
    ) external payable returns (uint _proposalID);

  
    function checkProposalCode(
        uint _proposalID,
        address _recipient,
        uint _amount,
        bytes memory _transactionData
    ) external returns (bool _codeChecksOut);

    
    function vote(uint _proposalID, bool _supportsProposal) external;

   
    function executeProposal(
        uint _proposalID,
        bytes memory _transactionData
    ) external returns (bool _success);


    function changeAllowedRecipients(address _recipient, bool _allowed) external returns (bool _success);


    function changeProposalDeposit(uint _proposalDeposit) external;


    function numberOfProposals() external returns (uint _numberOfProposals);


    function changeOrGetBlocked(address _account) external returns (bool);

    
    function unblockMyAcc() external returns (bool);


    receive() external payable;


    event ProposalAdded(
        uint indexed proposalID,
        address recipient,
        uint amount,
        string description
    );

    event Voted(uint indexed proposalID, bool position, address indexed voter);

    event ProposalCounted(uint indexed proposalID, bool result, uint quorum);

    event AllowedRecipientChanged(address indexed _recipient, bool _allowed);

}
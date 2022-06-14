// SPDX-License-Identifier: MIT

pragma solidity 0.8.14;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol";

contract Voting is Ownable {
    //address admin;

    //Evénements logs
    event VoterRegistered(address voterAddress); // Voter enregistré sur la whitelist
    event WorkflowStatusChange(
        WorkflowStatus previousStatus,
        WorkflowStatus newStatus
    ); //changement de statut => Ancien et nouveau
    event ProposalRegistered(uint256 proposalId); // Proposition enregistrée
    event Voted(address voter, uint256 proposalId); //A voté!

    constructor() {
        //définit l'admin au déploiement du contrat => le msg.sender devint admin
        //admin = msg.sender;
        proposals.push(Proposal("Vote blanc", 3));
    }

    /*modifier isAdmin {
            require(msg.sender == admin, "Action non autorisee, vous n'etes pas admin!");
            _;
        }*/

    //mapping des Voters identifiés par leur adresse
    mapping(address => Voter) Voters;

    struct Voter {
        //Personne qui vote
        bool isRegistered;
        bool hasVoted;
        uint256 votedProposalId;
    }
    struct Proposal {
        // Proposition
        string description;
        uint256 voteCount;
    }

    // Tableau dynamique de propositions.
    Proposal[] public proposals;

    enum WorkflowStatus {
        // Différents états du vote
        RegisteringVoters, //enregistrement Whitelist des Voters
        ProposalsRegistrationStarted,
        ProposalsRegistrationEnded,
        VotingSessionStarted,
        VotingSessionEnded,
        VotesTallied // votes comptabilisés
    }

    WorkflowStatus public workflowstatus;

    //*******Mes fonctions ********

    function setProposalRegistStart() external onlyOwner {
        //Fait passer au statut de début d'enregistrement de propositions
        require(
            workflowstatus == WorkflowStatus.RegisteringVoters,
            "Operation impossible en ce moment"
        );
        workflowstatus = WorkflowStatus.ProposalsRegistrationStarted;
        emit WorkflowStatusChange(
            WorkflowStatus.RegisteringVoters,
            WorkflowStatus.ProposalsRegistrationStarted
        );
    }

    function setPropRegistEnded() external onlyOwner {
        //Fait passer au statut de cloture d'enregistrement de propositions
        require(
            workflowstatus == WorkflowStatus.ProposalsRegistrationStarted,
            "Operation impossible en ce moment"
        );
        workflowstatus = WorkflowStatus.ProposalsRegistrationEnded;
        emit WorkflowStatusChange(
            WorkflowStatus.ProposalsRegistrationStarted,
            WorkflowStatus.ProposalsRegistrationEnded
        );
    }

    function setVotingStart() external onlyOwner {
        //Fait passer au statut de début du vote
        require(
            workflowstatus == WorkflowStatus.ProposalsRegistrationEnded,
            "Operation impossible en ce moment"
        );
        workflowstatus = WorkflowStatus.VotingSessionStarted;
        emit WorkflowStatusChange(
            WorkflowStatus.ProposalsRegistrationEnded,
            WorkflowStatus.VotingSessionStarted
        );
    }

    function setVotingEnd() external onlyOwner {
        //Fait passer au statut de cloture des votes
        require(
            workflowstatus == WorkflowStatus.VotingSessionStarted,
            "Operation impossible en ce moment"
        );
        workflowstatus = WorkflowStatus.VotingSessionEnded;
        emit WorkflowStatusChange(
            WorkflowStatus.VotingSessionStarted,
            WorkflowStatus.VotingSessionEnded
        );
    }

    function setVotesTallied() external onlyOwner {
        //Fait passer au statut de fin de comptage des votes
        require(
            workflowstatus == WorkflowStatus.VotingSessionEnded,
            "Operation impossible en ce moment"
        );
        workflowstatus = WorkflowStatus.VotesTallied;
        emit WorkflowStatusChange(
            WorkflowStatus.VotingSessionEnded,
            WorkflowStatus.VotesTallied
        );
    }

    function registerVoter(address _addr) public onlyOwner {
        // admin enregistre une whitelist de Voters
        require(
            Voters[_addr].isRegistered == false,
            "Vous etes deja enregistre dans la white list"
        );
        Voters[_addr].isRegistered = true;
        emit VoterRegistered(_addr);
    }

    function registerProposal(address _addr, string memory _description)
        public
    {
        //enregistrement d'une proposition
        require(
            Voters[_addr].isRegistered == true,
            "Vous n'etes pas enregistre dans la white list"
        ); // Il faut que la personne soit enregistrée sur la whitelist
        Proposal memory newProposal;
        newProposal.description = _description;
        newProposal.voteCount = 0;
        proposals.push(newProposal);
    }

    function Vote(uint256 _idProposal) external {
        // Vote
        require(
            Voters[msg.sender].isRegistered == true,
            "Vous n'etes pas enregistre dans la white list"
        ); //Le votant doit êtres sur la whitelist
        require(Voters[msg.sender].hasVoted == false, "Vous avez deja vote!"); //doit ne pas avoir déjà voté
        //rajouter un require pour être sûr que id proposal est dans le range du array des proposals********
        require(_idProposal < proposals.length, "ce choix n'existe pas");
        Voters[msg.sender].hasVoted = true;
        Voters[msg.sender].votedProposalId = _idProposal; // enregistrement de l'Id de la proposition pour laquelle on a voté
        //enregistrement et incrémentation du voteCount sur le tableau de Propositions
        proposals[_idProposal].voteCount += 1;
    }

    function getProposals() public view returns (Proposal[] memory) {
        return proposals;
    }

    /* function getWinningProposals() public view returns(Proposal [] memory) {
            
        }*/

    function getWinner() public view returns (uint256 _winnerProposal) {
        uint256 winnerVoteCount = 0;
        //string memory  winner;
        for (uint256 i = 0; i < proposals.length; i++) {
            if (proposals[i].voteCount > winnerVoteCount) {
                winnerVoteCount = proposals[i].voteCount; // nombre le plus élevé de votes
                _winnerProposal = i; //index de la case du tableau proposals qui à reçu le plus de votes
            }
            //
        }
    }

    function winnerName() external view returns (string memory propGagnant) {
        propGagnant = proposals[getWinner()].description;
    }
}

//SPDX-License-Identifier: MIT

pragma solidity 0.8.14;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol";

contract Voting is Ownable {

//-----------------------------------------------------------
//---------------Initialisation du WOrkflow------------------
//-----------------------------------------------------------

// Définition des évènements du workflow
event VoterRegistered(address voterAddress); 
event WorkflowStatusChange(WorkflowStatus previousStatus, WorkflowStatus newStatus);
event ProposalRegistered(uint proposalId);
event Voted (address voter, uint proposalId);

// Définition de l'enum permettant de suivre le changement d'état
enum WorkflowStatus {
RegisteringVoters,
ProposalsRegistrationStarted,
ProposalsRegistrationEnded,
VotingSessionStarted,
VotingSessionEnded,
VotesTallied
}

// Définition des structures, une pour les électeurs, une pour les propositions
struct Voter {
bool isRegistered;
bool hasVoted;
uint votedProposalId;
}

struct Proposal {
string description;
uint voteCount;
}

// Définition des mappings
mapping(address => Voter) public votersID; // Détail des électeurs par adresse
mapping(address => Proposal) public proposalsID; //Détail des propositions par adresse

// Tableau non fini répertoriant les propositions
Proposal[] public proposals;

// Fonction pour retrouver le nombre de propositions
function proposalsNumber() public returns(uint){
    return proposals.length+1;
}

// Définition du statut par défaut du workflow : enregistrement des électeurs
WorkflowStatus public statut = WorkflowStatus.RegisteringVoters;

// Fonction pour retourner à l'étape d'enregistrement des électeurs et tout recommencer
// function à faire dans un second temps s'il me reste du temps

//-----------------------------------------------------------
//----------------LANCEMENT DU WORKFLOW----------------------
//-----------------------------------------------------------


// Enregistrement des électeurs
function whitelist(address _address) external onlyOwner {
    require()
}

}

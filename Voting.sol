//SPDX-License-Identifier: MIT

pragma solidity 0.8.14;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol";

contract Voting is Ownable {


//-----------------------------------------------------------
//---------------Initialisation du Workflow------------------
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
mapping(address => Proposal) public proposalsID; // Détail des propositions par adresse

// Tableau non fini répertoriant les propositions
Proposal[] public proposals;

// ID de la proposition (incrémenté dans une fonction pour chaque proposition)
uint private proposalId = 0; // Je mets private pour ne pas que ce soit consultable, pour éviter les confusions

// ID de la proposition gagnante
uint public winningProposalId = 0;

// FONCTIONS D'AIDE GLOBALES

// 1 - Fonction pour retrouver le nombre de propositions
function proposalsNumber() public returns(uint){
    return proposals.length+1;
}

// 2 - Fonction pour observer les différentes propositions
function seeProposalWith_ID(uint _id) external view returns(string) {
    return proposals[_id].description;
}

// 3 - Fonction pour retrouver la proposition d'une adresse --> [UTILITE?]
function seeProposalWith_Addr(address _address) external view returns(string, uint) {
    return (proposalsID[_address].description, proposalsID[_address].voteCount);
}

// 4 - Fonction pour retourner à l'étape d'enregistrement des électeurs et tout recommencer
// function à faire dans un second temps s'il me reste du temps


//-----------------------------------------------------------
//----------------LANCEMENT DU WORKFLOW----------------------
//-----------------------------------------------------------

// PHASE 0 : Enregistrement des électeurs
// 1 - Définition du statut par défaut du workflow : enregistrement des électeurs
WorkflowStatus public statut = WorkflowStatus.RegisteringVoters;

// 2 - Whitelisting d'adresses par l'administrateur du vote
function whitelist(address _address) external onlyOwner {
    require(votersID[_address].isRegistered == false);
    require(statut == WorkflowStatus.RegisteringVoters);
    votersID[_address].isRegistered = true;
    emit VoterRegistered(_address); // Envoie l'info à l'interface que l'électeur est enregistré
}

//-----------------------------------------------------------

// PHASE 1 : Enregistrement des propositions

// 1 - Changement de phase --> Enregistrement des propositions
function startingRegistration() external onlyOwner {
    require(statut == WorkflowStatus.RegisteringVoters);
    statut = WorkflowStatus.ProposalsRegistrationStarted;
    emit WorkflowStatusChange(WorkflowStatus.RegisteringVoters, WorkflowStatus.ProposalsRegistrationStarted); // Envoie l'info à l'interface que le statut a changé
}

// 2 - Enregistrement des propositions

function registration(string _description) external {
    require(statut == WorkflowStatus.ProposalsRegistrationStarted);
    require(votersID[msg.sender].isRegistered == true);
    proposalsID[msg.sender] = Proposal(_description, 0);
    Proposal memory proposal = Proposal(_description, 0);
    proposals.push(proposal);
    emit ProposalRegistered(proposalId);
    proposalId += 1;
}

// 3 - Fin de la phase d'enregistrement
function endingRegistration() external onlyOwner {
    require(statut == WorkflowStatus.ProposalsRegistrationStarted);
    statut = WorkflowStatus.ProposalsRegistrationEnded;
    emit WorkflowStatusChange(WorkflowStatus.ProposalsRegistrationStarted, WorkflowStatus.ProposalsRegistrationEnded); // Envoie l'info à l'interface que le statut a changé
}

//-----------------------------------------------------------

// PHASE 2 : Phase de vote

// 1 - Changement de phase --> Vote
function startingVote() external onlyOwner {
    require(statut == WorkflowStatus.ProposalsRegistrationEnded);
    statut = WorkflowStatus.VotingSessionStarted;
    emit WorkflowStatusChange(WorkflowStatus.ProposalsRegistrationEnded, WorkflowStatus.VotingSessionStarted); // Envoie l'info à l'interface que le statut a changé
}

// 2 - Enregistrement des votes
function registration(_proposalId) external {
    require(statut == WorkflowStatus.VotingSessionStarted);
    require(votersID[msg.sender].isRegistered == true);
    
    emit Voted(msg.sender, _proposalId); // Envoie l'info du vote à l'interface
}

// 3 - Fin de la phase de vote
function endingVote() external onlyOwner {
    require(statut == WorkflowStatus.VotingSessionStarted);
    statut = WorkflowStatus.VotingSessionEnded;
    emit WorkflowStatusChange(WorkflowStatus.VotingSessionStarted, WorkflowStatus.VotingSessionEnded); // Envoie l'info à l'interface que le statut a changé
}

//-----------------------------------------------------------

// PHASE 3 : Phase de dépouillement des votes

// 1 - Comptabilisation des votes

// *FONCTION COMPTABILISATION*
// require le bon state + onlyOwner
// Renseigne l'uint winningProposalId, ou alors placer la fonction getWinner

// 2 - Fin de la phase de comptabilisation
function voteTallied() external onlyOwner {
    require(statut == WorkflowStatus.VotingSessionEnded);
    statut = WorkflowStatus.VotesTallied;
    emit WorkflowStatusChange(WorkflowStatus.VotingSessionEnded, WorkflowStatus.VotesTallied); // Envoie l'info à l'interface que le statut a changé
}

}
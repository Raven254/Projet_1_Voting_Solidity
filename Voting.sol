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
mapping(address => bool) public suiviProposition; // Permet de suivre qui a soumis une proposition

// Tableau non fini répertoriant les propositions
Proposal[] public proposals;

// ID de la proposition (incrémenté dans une fonction pour chaque proposition)
uint private proposalId = 0; // Je mets private pour ne pas que ce soit consultable, pour éviter les confusions

// ID de la proposition gagnante
uint public winningProposalId = 0;

// Nombre d'électeurs
uint public votersNumber = 0;

// FONCTIONS D'AIDE GLOBALES

// 1 - Fonction pour retrouver le nombre de propositions
function proposalsNumber() public view returns(uint){
    return proposals.length;
}

// 2 - Fonction pour observer les différentes propositions avec l'ID de celles-ci
function seeProposalWith_ID(uint _id) external view returns(string memory) {
    return proposals[_id].description;
}

// 3 - Fonction pour retrouver la proposition d'une adresse --> [UTILITE?]
function seeProposalWith_Addr(address _address) external view returns(string memory, uint) {
    return (proposalsID[_address].description, proposalsID[_address].voteCount);
}

// 4 - Fonction pour retourner à l'étape d'enregistrement des électeurs et tout recommencer
// function à faire dans un second temps s'il me reste du temps


//-----------------------------------------------------------
//----------------LANCEMENT DU WORKFLOW----------------------
//-----------------------------------------------------------

// PHASE 0 : Enregistrement des électeurs
// 1.a - Définition du statut par défaut du workflow : enregistrement des électeurs
WorkflowStatus public statut = WorkflowStatus.RegisteringVoters;

// 1.b - Fonction pour revenir à RegisteringVoters, au cas où
function startingRegisteringVoters() external onlyOwner {
    require(statut != WorkflowStatus.RegisteringVoters, unicode"Vous êtes déjà en phase d'enregistrement des électeurs.");
    emit WorkflowStatusChange(statut, WorkflowStatus.RegisteringVoters); // Envoie l'info à l'interface que le statut a changé
    statut = WorkflowStatus.RegisteringVoters;
}

// 2 - Whitelisting d'adresses par l'administrateur du vote
function whitelist(address _address) external onlyOwner {
    require(statut == WorkflowStatus.RegisteringVoters, unicode"Erreur : vous n'êtes pas à l'étape RegisteringVoters. Vérifiez le [statut] du workflow.");
    require(votersID[_address].isRegistered == false, unicode"L'électeur est déjà enregistré.");
    votersID[_address].isRegistered = true;
    votersNumber += 1;
    emit VoterRegistered(_address); // Envoie l'info à l'interface que l'électeur est enregistré
}

//-----------------------------------------------------------

// PHASE 1 : Enregistrement des propositions

// 1 - Changement de phase --> Enregistrement des propositions
function startingProposalsRegistration() external onlyOwner {
    require(statut == WorkflowStatus.RegisteringVoters, unicode"Erreur : vous n'êtes pas à l'étape RegisteringVoters. Vérifiez le [statut] du workflow.");
    statut = WorkflowStatus.ProposalsRegistrationStarted;
    emit WorkflowStatusChange(WorkflowStatus.RegisteringVoters, WorkflowStatus.ProposalsRegistrationStarted); // Envoie l'info à l'interface que le statut a changé
}

// 2 - Enregistrement des propositions

function proposalsRegistration(string calldata _description) external {
    require(statut == WorkflowStatus.ProposalsRegistrationStarted, unicode"Erreur : l'enregistrement des propositions n'a pas encore démarré / est terminée. Vérifiez le [statut] du workflow.");
    require(votersID[msg.sender].isRegistered == true, unicode"Erreur : vous n'êtes pas enregistré pour voter.");
    require(!suiviProposition[msg.sender], unicode"Erreur : vous avez déjà soumis une proposition.");
    proposalsID[msg.sender] = Proposal(_description, 0);
    Proposal memory proposal = Proposal(_description, 0);
    proposals.push(proposal);
    emit ProposalRegistered(proposalId);
    suiviProposition[msg.sender] = true;
    proposalId += 1;
}

// 3 - Fin de la phase d'enregistrement
function endingProposalsRegistration() external onlyOwner {
    require(statut == WorkflowStatus.ProposalsRegistrationStarted, unicode"Erreur : vous n'êtes pas à l'étape ProposalRegistrationStarted. Vérifiez le [statut] du workflow.");
    statut = WorkflowStatus.ProposalsRegistrationEnded;
    emit WorkflowStatusChange(WorkflowStatus.ProposalsRegistrationStarted, WorkflowStatus.ProposalsRegistrationEnded); // Envoie l'info à l'interface que le statut a changé
}

//-----------------------------------------------------------

// PHASE 2 : Phase de vote

// 1 - Changement de phase --> Vote
function startingVote() external onlyOwner {
    require(statut == WorkflowStatus.ProposalsRegistrationEnded, unicode"Erreur : vous n'êtes pas à l'étape ProposalsRegistrationEnded. Vérifiez le [statut] du workflow.");
    statut = WorkflowStatus.VotingSessionStarted;
    emit WorkflowStatusChange(WorkflowStatus.ProposalsRegistrationEnded, WorkflowStatus.VotingSessionStarted); // Envoie l'info à l'interface que le statut a changé
}

// 2 - Enregistrement des votes
function vote(uint _proposalId) external {
    require(statut == WorkflowStatus.VotingSessionStarted, unicode"Erreur : le vote n'a pas encore démarré / est terminé. Vérifiez le [statut] du workflow.");
    require(votersID[msg.sender].isRegistered == true, unicode"Erreur : vous n'êtes pas enregistré pour voter.");
    require(votersID[msg.sender].hasVoted == false, unicode"Erreur : vous avez déjà voté pour cette itération.");
    
    proposals[_proposalId].voteCount += 1; // Ajoute un vote à la proposition
    proposalsID[msg.sender].voteCount += 1;

    votersID[msg.sender].hasVoted = true; // Renseigne le vote de l'électeur
    votersID[msg.sender].votedProposalId = _proposalId;
    
    emit Voted(msg.sender, _proposalId); // Envoie l'info du vote à l'interface
}

// 3 - Fin de la phase de vote
function endingVote() external onlyOwner {
    require(statut == WorkflowStatus.VotingSessionStarted, unicode"Erreur : vous n'êtes pas à l'étape VotingSessionStarted. Vérifiez le [statut] du workflow.");
    statut = WorkflowStatus.VotingSessionEnded;
    emit WorkflowStatusChange(WorkflowStatus.VotingSessionStarted, WorkflowStatus.VotingSessionEnded); // Envoie l'info à l'interface que le statut a changé
}

//-----------------------------------------------------------

// PHASE 3 : Phase de dépouillement des votes

// 1 - Comptabilisation des votes
function voteCounting() external onlyOwner returns(uint) {
    require(statut == WorkflowStatus.VotingSessionEnded);
    uint IdCount = 0; // On garde cette variable pour suivre la proposition avec le max de votes.
    for(uint i = 1; i <= proposals.length - 1; i++) { // Boucle pour trouver le maximum, en comparant la clé i-1 avec la clé i.
        if (proposals[i].voteCount > proposals[i-1].voteCount){ // Cela peut occasionner un bug si 2 comptes sont égaux... Voir comment gérer
            IdCount = i;
        } else {
            IdCount = i-1;
        }
    }
    winningProposalId = IdCount;
    statut = WorkflowStatus.VotesTallied;
    emit WorkflowStatusChange(WorkflowStatus.VotingSessionEnded, WorkflowStatus.VotesTallied); // Envoie l'info à l'interface que le statut a changé
    return IdCount;
}

}
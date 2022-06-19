// // SPDX_Lincese

// pragma solidity ^0.8.0;

// contract MultiSig {

//     mapping(address => bool) public isAdmin;
//     uint totalAdmins;
//     uint internal _minAyeToPass;

//     struct Proposal {
//         address owner;
//         address callee;
//         bytes callData;
//         uint executableAt;

//         mapping(address => bool) votes;
//         uint approvals;
//         bool executed;
//     }
//     mapping(uint => Proposal) public proposals;
//     uint proposalsLength;


//     constructor(address[] memory owners_) {
//         uint l = owners_.length;
//         totalAdmins = l;
//         for (uint i; i < l; ++i) {
//             isAdmin[owners_[i]] = true;
//         }

//     }

//     modifier onlyAdmin() {
//         require(isAdmin[msg.sender], "MULTISIG: Not Allowed");
//         _;
//     }

//     function submitProposal(address callee, bytes calldata callData, uint executableAt_) public onlyAdmin {
//         proposals[proposalsLength].owner = msg.sender;
//         proposals[proposalsLength].callee = callee;
//         proposals[proposalsLength].callData = callData;
//         proposals[proposalsLength].executableAt= executableAt_;
//         proposalsLength++;
//     }

//     function approveProposal(uint id) public onlyAdmin {
//         Proposal storage p = proposals[id];
//         require(!p.executed, "MULTISIG: Proposal already executed");
//         if (!p.votes[msg.sender]) {
//             p.approvals++;
//             p.votes[msg.sender] = true;
//         }
//     }

//     function disapproveProposal(uint id) public onlyAdmin {
//         Proposal storage p = proposals[id];
//         require(!p.executed, "MULTISIG: Proposal already executed");
//         if (p.votes[msg.sender]) {
//             p.approvals--;
//             p.votes[msg.sender] = true;
//         }
//     }

//     function executeProposal(uint id) public onlyAdmin {
//         Proposal storage p = proposals[id];
//         require(!p.executed, "MULTISIG: Proposal already executed");
//         require(block.timestamp >= p.executableAt, "MULTISIG: Proposal not executable yet");
//     }


//     function addOwner(address owner) internal {
//         isAdmin[owner] = true;
//         totalAdmins++;
//     }

//     function removeOwner(address owner) internal {

//     }
// }

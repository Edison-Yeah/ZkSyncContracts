pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

// SPDX-License-Identifier: MIT OR Apache-2.0





import "./Ownable.sol";
import "./Config.sol";

/// @title Regenesis Multisig contract
/// @author Matter Labs
contract RegenesisMultisig is Ownable, Config {
    event CandidateAccepted(bytes32 oldRootHash, bytes32 newRootHash);
    event CandidateApproval(uint256 currentApproval);

    bytes32 public oldRootHash;
    bytes32 public newRootHash;

    bytes32 public candidateOldRootHash;
    bytes32 public candidateNewRootHash;

    /// @dev Stores boolean flags which means the confirmations of the upgrade for each member of security council
    mapping(uint256 => bool) internal securityCouncilApproves;
    uint256 internal numberOfApprovalsFromSecurityCouncil;

    uint256 securityCouncilThreshold;

    constructor(uint256 threshold) Ownable(msg.sender) {
        securityCouncilThreshold = threshold;
    }

    function submitHash(bytes32 _oldRootHash, bytes32 _newRootHash) external {
        // Only zkSync team can submit the hashes
        require(msg.sender == getMaster(), "1");

        candidateOldRootHash = _oldRootHash;
        candidateNewRootHash = _newRootHash;

        oldRootHash = bytes32(0);
        newRootHash = bytes32(0);

        for (uint256 i = 0; i < SECURITY_COUNCIL_MEMBERS_NUMBER; ++i) {
            securityCouncilApproves[i] = false;
        }
        numberOfApprovalsFromSecurityCouncil = 0;
    }

    function approveHash(bytes32 _oldRootHash, bytes32 _newRootHash) external {
        require(_oldRootHash == candidateOldRootHash, "2");
        require(_newRootHash == candidateNewRootHash, "3");

        address payable[SECURITY_COUNCIL_MEMBERS_NUMBER] memory SECURITY_COUNCIL_MEMBERS = [
            0x22C3F9177F485bF9a058cE4C7253Da81a59495Db,0x56dF84566a67e87808A73dA0Be61a40bda3e2AFA,0xCE004d039cD86b08274FC453bd5536E6e9F6Fac7
        ];
        for (uint256 id = 0; id < SECURITY_COUNCIL_MEMBERS_NUMBER; ++id) {
            if (SECURITY_COUNCIL_MEMBERS[id] == msg.sender) {
                require(securityCouncilApproves[id] == false);
                securityCouncilApproves[id] = true;
                numberOfApprovalsFromSecurityCouncil++;
                emit CandidateApproval(numberOfApprovalsFromSecurityCouncil);

                // It is ok to check for strict equality since the numberOfApprovalsFromSecurityCouncil
                // is increased by one at a time. It is better to do so not to emit the
                // CandidateAccepted event more than once
                if (numberOfApprovalsFromSecurityCouncil == securityCouncilThreshold) {
                    oldRootHash = candidateOldRootHash;
                    newRootHash = candidateNewRootHash;
                    emit CandidateAccepted(oldRootHash, newRootHash);
                }
            }
        }
    }
}

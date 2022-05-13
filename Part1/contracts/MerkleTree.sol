//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import {PoseidonT3} from "./Poseidon.sol"; //an existing library to perform Poseidon hash on solidity
import "./verifier.sol"; //inherits with the MerkleTreeInclusionProof verifier contract

contract MerkleTree is Verifier {
    uint256[] public hashes; // the Merkle tree in flattened array form
    uint256 public index = 0; // the current index of the first unfilled leaf
    uint256 public root; // the current Merkle root

    uint256 public constant MAX_LEAVES = 8; // max number of leaves in the tree
    uint256 public constant TREE_SIZE = 15; // the total number of hashes in the tree, including leaves

    constructor() {
        // [assignment] initialize a Merkle tree of 8 with blank leaves

        // initialize full tree with zeroes
        for (uint256 i = 0; i < TREE_SIZE; i++) {
            hashes.push(0);
        }
    }

    function insertLeaf(uint256 hashedLeaf) public returns (uint256) {
        // [assignment] insert a hashed leaf into the Merkle tree
        require(index < MAX_LEAVES, "Merkle tree is already full!"); // revert transaction if the tree is already full
        hashes[index] = hashedLeaf; // save leaf to current index
        index++; // update index for the next leaf

        // calculate new root
        // note: this loop recalculates all the hashes that go after the leaves
        // this can be optimized to calculate only the hashes that need to be updated
        uint256 hashIdx = MAX_LEAVES; // all leaves are already hashes, so first hash to be aclculated is at index MAX_LEAVES
        for (uint256 i = 0; i < TREE_SIZE - 1; i += 2) {
            // iterate over pairs of hashes in the tree
            uint256 h = PoseidonT3.poseidon([hashes[i], hashes[i + 1]]); // calculate the hash of the pair of hashes
            hashes[hashIdx] = h; // add the resulting hash into the array
            hashIdx++; // move on to build the next hash
        }

        root = hashes[TREE_SIZE - 1]; // the final hash is the merkle root, update it's value
        return root;
    }

    function verify(
        uint256[2] memory a,
        uint256[2][2] memory b,
        uint256[2] memory c,
        uint256[1] memory input
    ) public view returns (bool) {
        // [assignment] verify an inclusion proof and check that the proof root matches current root

        // verify the inclusion proof
        if (!Verifier.verifyProof(a, b, c, input)) {
            return false;
        }

        // verify that the merkle root from the proof matches the merkle root in contract
        uint256 proofRoot = input[0];
        if (proofRoot != root) {
            return false;
        }

        // all good
        return true;
    }
}

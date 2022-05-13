pragma circom 2.0.0;

include "../node_modules/circomlib/circuits/poseidon.circom";
include "../node_modules/circomlib/circuits/switcher.circom";

template CheckRoot(n) { // compute the root of a MerkleTree of n Levels 
    signal input leaves[2**n];
    signal output root;

    //[assignment] insert your code here to calculate the Merkle root from 2^n leaves

    var totalHashes = 2**(n + 1) - 1; // full n-level tree has 2^(n+1) nodes
    signal hashes[totalHashes]; // hashes array holds  all tree hashes in bottom-up left-to-right order

    // copy already calculated hashes into hashes array
    for (var i = 0; i < 2**n; i++) {
        hashes[i] <== leaves[i];
    }

    // components for hash calculations
    component hashers[totalHashes];

    // calculate the rest of the hashes of the tree and write them to the array
    // we start from hash at 2**n because 2**n hashes are already passed as inputs (and copied into hashes array)
    var hashIdx = 2**n;
    // iterate over 2 adjacent elements (that's why i+=2)
    for (var i = 0; i < totalHashes - 1; i += 2) {
        // calculate the hash of the current two elements
        hashers[hashIdx] = Poseidon(2);
        hashers[hashIdx].inputs[0] <== hashes[i];
        hashers[hashIdx].inputs[1] <== hashes[i+1];
        // append the calculated hash to the hashes array
        hashes[hashIdx] <== hashers[hashIdx].out;
        // increment the index where the next hash will go
        hashIdx++;
    }

    // the last element in hashes array is the merkle root
    root <== hashes[totalHashes-1];
}

template MerkleTreeInclusionProof(n) {
    signal input leaf;
    signal input path_elements[n];
    signal input path_index[n]; // path index are 0's and 1's indicating whether the current element is on the left or right
    signal output root; // note that this is an OUTPUT signal

    //[assignment] insert your code here to compute the root from a leaf and elements along the path

    component switchers[n]; // switchers are used to revers the order of hasher's arguments when it's needed (depending on whether node is left or right as related to it's parent)
    component hashers[n]; // hashers are used to compute hashes

    for (var i = 0; i < n; i++) {
        switchers[i] = Switcher();
        switchers[i].L <== i == 0 ? leaf : hashers[i-1].out; // use leaf if level is zero, otherwise the previous hash
        switchers[i].R <== path_elements[i]; // second argument to hash comes from proof path
        switchers[i].sel <== path_index[i];  // switch to order if needed

        // compute hash
        hashers[i] = Poseidon(2);
        hashers[i].inputs[0] <== switchers[i].outL;
        hashers[i].inputs[1] <== switchers[i].outR;
    }

    // last hash is the merkle root
    root <== hashers[n-1].out;
}
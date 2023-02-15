pragma circom 2.1.0;

include "../incrementalMerkleTree.circom";
include "../node_modules/circomlib/circuits/poseidon.circom";
include "../node_modules/circomlib/circuits/comparators.circom";

template IsInInterval(n) {
    signal input in[3];

    signal output out;

    signal let <== LessEqThan(n)([in[1], in[2]]);
    signal get <== GreaterEqThan(n)([in[1], in[0]]);

    out <== let * get;
}

template RLN(depth) {
    // Private signals
    signal input identity_secret;
    signal input message_id;
    signal input path_elements[depth][1];
    signal input identity_path_index[depth];

    // Public signals
    signal input x;
    signal input external_nullifier;
    signal input message_limit;

    // Outputs
    signal output y;
    signal output root;
    signal output nullifier;

    // Calculate identity_commitment = Poseidon(identity_secret)
    signal identity_commitment <== Poseidon(1)([identity_secret]);

    // Merkle tree root output
    root <== MerkleTreeInclusionProof(depth)(identity_commitment, identity_path_index, path_elements);

    // Check that 1 <= message_id <= message_limit
    signal checkInterval <== IsInInterval(16)([1, message_id, message_limit]);
    checkInterval === 1;

    // Linear equation/share calculation constraints:
    signal a_1 <== Poseidon(3)([identity_secret, external_nullifier, message_id]);
    y <== identity_secret + a_1 * x;

    // Internal nullifier = Poseidon(a_1) output
    nullifier <== Poseidon(1)([a_1]);
}

component main { public [x, message_limit, external_nullifier] } = RLN(20);
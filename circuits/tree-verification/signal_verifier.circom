pragma circom 2.0.2;

include "../merkleTree.circom";
include "../signalHasher.circom";

// Checks private signals are included as leaves in the tree.
// Cool because miner inputs are private but we can still verify they're in the tree,
// and so we can prove that we operated on the correct data
template SignalVerifier(numSignals, levels) {
    signal input signals[numSignals][12];
    signal input pathElements[numSignals][levels];
    signal input pathIndices[numSignals][levels];
    signal input merkle_root;
    signal output valid;

    component hashers[numSignals];
    signal leafHashes[numSignals];

    for (var i = 0; i < numSignals; i++) {
        hashers[i] = SignalHasher();
        hashers[i].miner_hotkey[0] <== signals[i][0];
        hashers[i].miner_hotkey[1] <== signals[i][1];
        hashers[i].trade_pair_id <== signals[i][2];
        hashers[i].order_type <== signals[i][3];
        hashers[i].leverage_scaled <== signals[i][4];
        hashers[i].price_scaled <== signals[i][5];
        hashers[i].processed_ms <== signals[i][6];
        hashers[i].order_uuid[0] <== signals[i][7];
        hashers[i].order_uuid[1] <== signals[i][8];
        hashers[i].position_uuid[0] <== signals[i][9];
        hashers[i].position_uuid[1] <== signals[i][10];
        hashers[i].src <== signals[i][11];
        leafHashes[i] <== hashers[i].signal_hash;
    }

    component merkleCheckers[numSignals];
    signal validChecks[numSignals];

    for (var i = 0; i < numSignals; i++) {
        merkleCheckers[i] = MerkleTreeChecker(levels);
        merkleCheckers[i].leaf <== leafHashes[i];
        merkleCheckers[i].root <== merkle_root;

        for (var j = 0; j < levels; j++) {
            merkleCheckers[i].pathElements[j] <== pathElements[i][j];
            merkleCheckers[i].pathIndices[j] <== pathIndices[i][j];
        }
        validChecks[i] <== 1;
    }

    signal validProducts[numSignals];
    validProducts[0] <== validChecks[0];

    for (var i = 1; i < numSignals; i++) {
        validProducts[i] <== validProducts[i-1] * validChecks[i];
    }

    valid <== validProducts[numSignals-1];
}

// This will verify a merkle root for each miner, max tree depth of 15 gives us max 32768 leaves
// Some implementations just create a new tree when it'll overflow, which seems viable..
component main {public [merkle_root]} = SignalVerifier(256, 15);

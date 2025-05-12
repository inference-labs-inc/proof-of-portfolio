pragma circom 2.0.2;

include "../../node_modules/circomlib/circuits/poseidon.circom";

// Hashes private signals to create a leaf node
// basically just a description of the signal and appending it all together to get a hash
template SignalHasher() {
    signal input miner_hotkey[2];
    signal input trade_pair_id;
    signal input order_type;
    signal input leverage_scaled;
    signal input price_scaled;
    signal input processed_ms;
    signal input order_uuid[2];
    signal input position_uuid[2];
    signal input src;

    signal output signal_hash;

    component hasher = Poseidon(12);

    hasher.inputs[0] <== miner_hotkey[0];
    hasher.inputs[1] <== miner_hotkey[1];
    hasher.inputs[2] <== trade_pair_id;
    hasher.inputs[3] <== order_type;
    hasher.inputs[4] <== leverage_scaled;
    hasher.inputs[5] <== price_scaled;
    hasher.inputs[6] <== processed_ms;
    hasher.inputs[7] <== order_uuid[0];
    hasher.inputs[8] <== order_uuid[1];
    hasher.inputs[9] <== position_uuid[0];
    hasher.inputs[10] <== position_uuid[1];
    hasher.inputs[11] <== src;

    signal_hash <== hasher.out;
}

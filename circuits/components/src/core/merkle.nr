use std;

// Globals
pub global MERKLE_DEPTH: u32 = 4;

pub struct TradingSignal {
    pub miner_hotkey: [Field; 2],
    pub trade_pair_id: Field,
    pub order_type: Field,
    pub leverage_scaled: Field,
    pub price_scaled: Field,
    pub processed_ms: Field,
    pub order_uuid: [Field; 2],
    pub position_uuid: [Field; 2],
    pub src: Field,
}

pub fn hash_signal(signal: TradingSignal) -> Field {
    let mut hash_inputs: [Field; 11] = [
        signal.miner_hotkey[0],
        signal.miner_hotkey[1],
        signal.trade_pair_id,
        signal.order_type,
        signal.leverage_scaled,
        signal.price_scaled,
        signal.processed_ms,
        signal.order_uuid[0],
        signal.order_uuid[1],
        signal.position_uuid[0],
        signal.position_uuid[1],
    ];
    std::hash::pedersen_hash(hash_inputs)
}

pub fn merkle_inclusion_check(
    leaf: Field,
    merkle_root: Field,
    path_elements: [Field; MERKLE_DEPTH],
    path_indices: [Field; MERKLE_DEPTH],
) -> bool {
    let mut current_hash = leaf;

    for i in 0..MERKLE_DEPTH {
        let path_element = path_elements[i];
        let is_right = path_indices[i];
        let mut hash_inputs = [current_hash, path_element];
        if is_right == 1 {
            hash_inputs = [path_element, current_hash];
        };
        current_hash = std::hash::pedersen_hash(hash_inputs);
    }

    current_hash == merkle_root
}

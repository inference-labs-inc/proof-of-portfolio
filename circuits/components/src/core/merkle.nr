use std;

// Globals
pub global MERKLE_DEPTH: u32 = 8;

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

#[test]
fn test_hash_signal_consistency() {
    let signal1 = TradingSignal {
        miner_hotkey: [1, 2],
        trade_pair_id: 10,
        order_type: 1,
        leverage_scaled: 1000,
        price_scaled: 50000,
        processed_ms: 1234567890,
        order_uuid: [100, 200],
        position_uuid: [300, 400],
        src: 1,
    };

    let hash1 = hash_signal(signal1);
    let hash2 = hash_signal(signal1);
    assert(hash1 == hash2);
}

#[test]
fn test_hash_signal_different_inputs() {
    let signal1 = TradingSignal {
        miner_hotkey: [1, 2],
        trade_pair_id: 10,
        order_type: 1,
        leverage_scaled: 1000,
        price_scaled: 50000,
        processed_ms: 1234567890,
        order_uuid: [100, 200],
        position_uuid: [300, 400],
        src: 1,
    };

    let signal2 = TradingSignal {
        miner_hotkey: [1, 2],
        trade_pair_id: 11,
        order_type: 1,
        leverage_scaled: 1000,
        price_scaled: 50000,
        processed_ms: 1234567890,
        order_uuid: [100, 200],
        position_uuid: [300, 400],
        src: 1,
    };

    let hash1 = hash_signal(signal1);
    let hash2 = hash_signal(signal2);
    assert(hash1 != hash2);
}

#[test]
fn test_signal_hash_with_zeros() {
    let signal = TradingSignal {
        miner_hotkey: [0, 0],
        trade_pair_id: 0,
        order_type: 0,
        leverage_scaled: 0,
        price_scaled: 0,
        processed_ms: 0,
        order_uuid: [0, 0],
        position_uuid: [0, 0],
        src: 0,
    };

    let hash = hash_signal(signal);
    assert(hash != 0);
}

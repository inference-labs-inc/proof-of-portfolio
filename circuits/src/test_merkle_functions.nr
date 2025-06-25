use components::core::merkle::{hash_signal, TradingSignal};

#[test]
fn test_hash_signal_basic() {
    let signal = TradingSignal {
        miner_hotkey: [1, 2],
        trade_pair_id: 100,
        order_type: 1,
        leverage_scaled: 15000,
        price_scaled: 50000,
        processed_ms: 1234567890,
        order_uuid: [10, 20],
        position_uuid: [30, 40],
        src: 1,
    };

    let hash = hash_signal(signal);
    // Test deterministic behavior - same input should give same hash
    let hash_again = hash_signal(signal);
    assert(hash == hash_again);
}

#[test]
fn test_hash_signal_different_inputs() {
    let signal1 = TradingSignal {
        miner_hotkey: [1, 2],
        trade_pair_id: 100,
        order_type: 1,
        leverage_scaled: 15000,
        price_scaled: 50000,
        processed_ms: 1234567890,
        order_uuid: [10, 20],
        position_uuid: [30, 40],
        src: 1,
    };

    let signal2 = TradingSignal {
        miner_hotkey: [3, 4], // Different hotkey
        trade_pair_id: 100,
        order_type: 1,
        leverage_scaled: 15000,
        price_scaled: 50000,
        processed_ms: 1234567890,
        order_uuid: [10, 20],
        position_uuid: [30, 40],
        src: 1,
    };

    let hash1 = hash_signal(signal1);
    let hash2 = hash_signal(signal2);

    // Note: We expect different hashes but collisions are theoretically possible
    // This test validates the common case behavior
    assert(hash1 != hash2);
}

#[test]
fn test_hash_signal_zero_values() {
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
    // Hash function should work even with all zero values - test determinism
    let hash_again = hash_signal(signal);
    assert(hash == hash_again);
}

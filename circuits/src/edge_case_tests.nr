use crate::{calculate_simple_returns, MAX_SIGNALS};
use components::core::merkle::TradingSignal;

#[test]
fn test_empty_signals() {
    let signals: [TradingSignal; MAX_SIGNALS] = [
        TradingSignal {
            miner_hotkey: [0, 0],
            trade_pair_id: 0,
            order_type: 0,
            leverage_scaled: 0,
            price_scaled: 0,
            processed_ms: 0,
            order_uuid: [0, 0],
            position_uuid: [0, 0],
            src: 0,
        }; MAX_SIGNALS
    ];

    let (returns, count) = calculate_simple_returns(signals, 0);
    assert(count == 0);
}

#[test]
fn test_single_signal_no_trade() {
    let mut signals: [TradingSignal; MAX_SIGNALS] = [
        TradingSignal {
            miner_hotkey: [0, 0],
            trade_pair_id: 0,
            order_type: 0,
            leverage_scaled: 0,
            price_scaled: 0,
            processed_ms: 0,
            order_uuid: [0, 0],
            position_uuid: [0, 0],
            src: 0,
        }; MAX_SIGNALS
    ];

    signals[0] = TradingSignal {
        miner_hotkey: [0, 0],
        trade_pair_id: 0,
        order_type: 1,
        leverage_scaled: 100,
        price_scaled: 10000,
        processed_ms: 1000,
        order_uuid: [0x1111111111111111, 0x1111111111111111],
        position_uuid: [0x1111111111111111, 0x1111111111111111],
        src: 0,
    };

    let (returns, count) = calculate_simple_returns(signals, 1);
    assert(count == 0);
}

#[test]
fn test_invalid_order_types() {
    let mut signals: [TradingSignal; MAX_SIGNALS] = [
        TradingSignal {
            miner_hotkey: [0, 0],
            trade_pair_id: 0,
            order_type: 0,
            leverage_scaled: 0,
            price_scaled: 0,
            processed_ms: 0,
            order_uuid: [0, 0],
            position_uuid: [0, 0],
            src: 0,
        }; MAX_SIGNALS
    ];

    signals[0] = TradingSignal {
        miner_hotkey: [0, 0],
        trade_pair_id: 0,
        order_type: 99,
        leverage_scaled: 100,
        price_scaled: 10000,
        processed_ms: 1000,
        order_uuid: [0x1111111111111111, 0x1111111111111111],
        position_uuid: [0x1111111111111111, 0x1111111111111111],
        src: 0,
    };

    signals[1] = TradingSignal {
        miner_hotkey: [0, 0],
        trade_pair_id: 0,
        order_type: 88,
        leverage_scaled: 100,
        price_scaled: 11000,
        processed_ms: 2000,
        order_uuid: [0x2222222222222222, 0x2222222222222222],
        position_uuid: [0x1111111111111111, 0x1111111111111111],
        src: 0,
    };

    let (returns, count) = calculate_simple_returns(signals, 2);
    assert(count == 0);
}

#[test]
fn test_close_without_open() {
    let mut signals: [TradingSignal; MAX_SIGNALS] = [
        TradingSignal {
            miner_hotkey: [0, 0],
            trade_pair_id: 0,
            order_type: 0,
            leverage_scaled: 0,
            price_scaled: 0,
            processed_ms: 0,
            order_uuid: [0, 0],
            position_uuid: [0, 0],
            src: 0,
        }; MAX_SIGNALS
    ];

    signals[0] = TradingSignal {
        miner_hotkey: [0, 0],
        trade_pair_id: 0,
        order_type: 2,
        leverage_scaled: 100,
        price_scaled: 11000,
        processed_ms: 2000,
        order_uuid: [0x2222222222222222, 0x2222222222222222],
        position_uuid: [0x1111111111111111, 0x1111111111111111],
        src: 0,
    };

    let (returns, count) = calculate_simple_returns(signals, 1);
    assert(count == 0);
}

#[test]
fn test_multiple_opens_without_close() {
    let mut signals: [TradingSignal; MAX_SIGNALS] = [
        TradingSignal {
            miner_hotkey: [0, 0],
            trade_pair_id: 0,
            order_type: 0,
            leverage_scaled: 0,
            price_scaled: 0,
            processed_ms: 0,
            order_uuid: [0, 0],
            position_uuid: [0, 0],
            src: 0,
        }; MAX_SIGNALS
    ];

    signals[0] = TradingSignal {
        miner_hotkey: [0, 0],
        trade_pair_id: 0,
        order_type: 1,
        leverage_scaled: 100,
        price_scaled: 10000,
        processed_ms: 1000,
        order_uuid: [0x1111111111111111, 0x1111111111111111],
        position_uuid: [0x1111111111111111, 0x1111111111111111],
        src: 0,
    };

    signals[1] = TradingSignal {
        miner_hotkey: [0, 0],
        trade_pair_id: 0,
        order_type: 1,
        leverage_scaled: 150,
        price_scaled: 12000,
        processed_ms: 2000,
        order_uuid: [0x2222222222222222, 0x2222222222222222],
        position_uuid: [0x2222222222222222, 0x2222222222222222],
        src: 0,
    };

    let (returns, count) = calculate_simple_returns(signals, 2);
    assert(count == 0);
}

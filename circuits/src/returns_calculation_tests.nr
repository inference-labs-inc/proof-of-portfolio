use crate::{calculate_simple_returns, MAX_SIGNALS};
use components::core::merkle::TradingSignal;

#[test]
fn test_single_long_trade() {
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
        order_type: 2,
        leverage_scaled: 100,
        price_scaled: 11000,
        processed_ms: 2000,
        order_uuid: [0x2222222222222222, 0x2222222222222222],
        position_uuid: [0x1111111111111111, 0x1111111111111111],
        src: 0,
    };

    let (returns, count) = calculate_simple_returns(signals, 2);

    assert(count == 1);
    assert(returns[0] == 1000);
}

#[test]
fn test_single_short_trade() {
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
        order_type: 3,
        leverage_scaled: 200,
        price_scaled: 20000,
        processed_ms: 1000,
        order_uuid: [0x3333333333333333, 0x3333333333333333],
        position_uuid: [0x3333333333333333, 0x3333333333333333],
        src: 0,
    };

    signals[1] = TradingSignal {
        miner_hotkey: [0, 0],
        trade_pair_id: 0,
        order_type: 4,
        leverage_scaled: 200,
        price_scaled: 18000,
        processed_ms: 2000,
        order_uuid: [0x4444444444444444, 0x4444444444444444],
        position_uuid: [0x3333333333333333, 0x3333333333333333],
        src: 0,
    };

    let (returns, count) = calculate_simple_returns(signals, 2);

    assert(count == 1);
    assert(returns[0] == 2000);
}

#[test]
fn test_multiple_trades_mixed() {
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
        order_type: 2,
        leverage_scaled: 100,
        price_scaled: 11000,
        processed_ms: 2000,
        order_uuid: [0x2222222222222222, 0x2222222222222222],
        position_uuid: [0x1111111111111111, 0x1111111111111111],
        src: 0,
    };

    signals[2] = TradingSignal {
        miner_hotkey: [0, 0],
        trade_pair_id: 0,
        order_type: 3,
        leverage_scaled: 150,
        price_scaled: 5000,
        processed_ms: 3000,
        order_uuid: [0x3333333333333333, 0x3333333333333333],
        position_uuid: [0x3333333333333333, 0x3333333333333333],
        src: 0,
    };

    signals[3] = TradingSignal {
        miner_hotkey: [0, 0],
        trade_pair_id: 0,
        order_type: 4,
        leverage_scaled: 150,
        price_scaled: 4000,
        processed_ms: 4000,
        order_uuid: [0x4444444444444444, 0x4444444444444444],
        position_uuid: [0x3333333333333333, 0x3333333333333333],
        src: 0,
    };

    let (returns, count) = calculate_simple_returns(signals, 4);

    assert(count == 2);
    assert(returns[0] == 1000);
    assert(returns[1] == 3000);
}

#[test]
fn test_incomplete_trades_ignored() {
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
fn test_zero_entry_price_handling() {
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
        price_scaled: 0,
        processed_ms: 1000,
        order_uuid: [0x1111111111111111, 0x1111111111111111],
        position_uuid: [0x1111111111111111, 0x1111111111111111],
        src: 0,
    };

    signals[1] = TradingSignal {
        miner_hotkey: [0, 0],
        trade_pair_id: 0,
        order_type: 2,
        leverage_scaled: 100,
        price_scaled: 1000,
        processed_ms: 2000,
        order_uuid: [0x2222222222222222, 0x2222222222222222],
        position_uuid: [0x1111111111111111, 0x1111111111111111],
        src: 0,
    };

    let (returns, count) = calculate_simple_returns(signals, 2);

    assert(count == 1);
    assert(returns[0] == 10000000);
}

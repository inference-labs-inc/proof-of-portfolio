use crate::{calculate_simple_returns, MAX_SIGNALS};
use components::core::merkle::TradingSignal;

#[test]
fn test_extreme_leverage() {
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
        leverage_scaled: 10000,
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
        leverage_scaled: 10000,
        price_scaled: 10001,
        processed_ms: 2000,
        order_uuid: [0x2222222222222222, 0x2222222222222222],
        position_uuid: [0x1111111111111111, 0x1111111111111111],
        src: 0,
    };

    let (returns, count) = calculate_simple_returns(signals, 2);

    assert(count == 1);
    assert(returns[0] == 100);
}

#[test]
fn test_minimum_price_movement() {
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
        price_scaled: 100000,
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
        price_scaled: 100001,
        processed_ms: 2000,
        order_uuid: [0x2222222222222222, 0x2222222222222222],
        position_uuid: [0x1111111111111111, 0x1111111111111111],
        src: 0,
    };

    let (returns, count) = calculate_simple_returns(signals, 2);

    assert(count == 1);
    assert(returns[0] == 0);
}

#[test]
fn test_maximum_signals() {
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

    for i in 0..MAX_SIGNALS {
        if i % 2 == 0 {
            signals[i] = TradingSignal {
                miner_hotkey: [0, 0],
                trade_pair_id: 0,
                order_type: 1,
                leverage_scaled: 100,
                price_scaled: 10000,
                processed_ms: (i as Field) * 1000,
                order_uuid: [(i as Field), (i as Field)],
                position_uuid: [(i as Field), (i as Field)],
                src: 0,
            };
        } else {
            signals[i] = TradingSignal {
                miner_hotkey: [0, 0],
                trade_pair_id: 0,
                order_type: 2,
                leverage_scaled: 100,
                price_scaled: 11000,
                processed_ms: (i as Field) * 1000,
                order_uuid: [(i as Field), (i as Field)],
                position_uuid: [((i - 1) as Field), ((i - 1) as Field)],
                src: 0,
            };
        }
    }

    let (returns, count) = calculate_simple_returns(signals, MAX_SIGNALS);

    assert(count == (MAX_SIGNALS / 2));
}

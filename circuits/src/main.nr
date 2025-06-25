use components::core::{
    drawdown::daily_max_drawdown, omega::omega, sharpe::sharpe, sortino::sortino,
    tstat::statistical_confidence,
};
use components::core::merkle::{hash_signal, MERKLE_DEPTH, merkle_inclusion_check, TradingSignal};
use components::utils::{
    ann_excess_return::ann_excess_return, ann_volatility::ann_volatility, average::average,
    variance::variance,
};

mod integration_tests;
mod merkle_tests;
mod returns_calculation_tests;
mod edge_case_tests;
mod extreme_value_tests;
mod test_calmar;
mod test_core_functions;
mod test_utils_functions;
mod test_merkle_functions;

global MAX_SIGNALS: u32 = 256;

pub fn calculate_simple_returns(
    signals: [TradingSignal; MAX_SIGNALS],
    actual_len: u32,
) -> ([i64; MAX_SIGNALS], u32) {
    let mut returns = [0; MAX_SIGNALS];
    let mut return_count = 0;

    let mut position_open = false;
    let mut entry_price: i64 = 0;
    let mut leverage: i64 = 1;
    let mut position_is_short = false;

    for i in 0..MAX_SIGNALS {
        if (i as u32) < actual_len {
            let signal = signals[i];

            let type_u8 = signal.order_type as u8;

            if (type_u8 == 1) | (type_u8 == 3) {
                if !position_open {
                    entry_price = signal.price_scaled as i64;
                    leverage = signal.leverage_scaled as i64;
                    position_is_short = type_u8 == 3;
                    position_open = true;
                }
            } else if (type_u8 == 2) | (type_u8 == 4) {
                if position_open {
                    let exit_price = signal.price_scaled as i64;
                    let safe_entry_price = if entry_price == 0 { 1 } else { entry_price };
                    let mut price_diff = exit_price - entry_price;

                    if position_is_short {
                        price_diff = -price_diff;
                    }

                    let return_value = (price_diff * leverage * 100) / safe_entry_price;

                    if (return_count as u32) < MAX_SIGNALS {
                        returns[return_count] = return_value;
                        return_count = return_count + 1;
                    }
                    position_open = false;
                }
            }
        }
    }

    (returns, return_count as u32)
}

fn main(
    signals: [TradingSignal; MAX_SIGNALS],
    actual_len: u32,
    path_elements: [[Field; MERKLE_DEPTH]; MAX_SIGNALS],
    path_indices: [[Field; MERKLE_DEPTH]; MAX_SIGNALS],
    merkle_root: Field,
    RISK_FREE_RATE: i64,
) -> pub [Field; 9] {
    let mut all_verified = true;
    for i in 0..MAX_SIGNALS {
        if (i as u32) < actual_len {
            let signal_hash = hash_signal(signals[i]);
            let verified =
                merkle_inclusion_check(signal_hash, merkle_root, path_elements[i], path_indices[i]);
            all_verified = all_verified & verified;
        }
    }
    assert(all_verified);

    let (returns, n_returns) = calculate_simple_returns(signals, actual_len);

    let avg = average(returns, n_returns);
    let var = variance(returns, n_returns, 1);
    let aer = ann_excess_return(returns, n_returns, RISK_FREE_RATE);
    let avol = ann_volatility(returns, n_returns, 1);
    let sh = sharpe(returns, n_returns, RISK_FREE_RATE);
    let om = omega(returns, n_returns);
    let so = sortino(returns, n_returns, RISK_FREE_RATE);
    let dmd = daily_max_drawdown(returns, n_returns);
    let sc = statistical_confidence(returns, n_returns);

    [
        avg as Field,
        var as Field,
        aer as Field,
        avol as Field,
        sh as Field,
        om as Field,
        so as Field,
        dmd as Field,
        sc as Field,
    ]
}

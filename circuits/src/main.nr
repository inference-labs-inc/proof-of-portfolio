use components::core::cps_to_log_returns::{cps_to_log_returns, MAX_CHECKPOINTS, MAX_DAYS};
use components::core::{drawdown::daily_max_drawdown, sharpe::sharpe};
use components::core::merkle::{
    build_merkle_root, hash_return, hash_signal, MAX_RETURNS, MAX_SIGNALS, MERKLE_DEPTH,
    merkle_inclusion_check, TradingSignal,
};
use components::utils::constants::ARRAY_SIZE;

global RISK_FREE_RATE: i64 = 0;

fn main(
    gains: [i64; MAX_CHECKPOINTS],
    losses: [i64; MAX_CHECKPOINTS],
    last_update_times: [u64; MAX_CHECKPOINTS],
    accum_times: [u64; MAX_CHECKPOINTS],
    checkpoint_count: u32,
    target_duration: u64,
    signals: [TradingSignal; MAX_SIGNALS],
    signals_count: u32,
    path_elements: [[Field; MERKLE_DEPTH]; MAX_SIGNALS],
    path_indices: [[Field; MERKLE_DEPTH]; MAX_SIGNALS],
    signals_merkle_root: pub Field,
    returns_merkle_root: pub Field,
) -> pub [Field; 2] {
    // Convert checkpoints to log returns
    let (log_returns, valid_days) = cps_to_log_returns(
        gains,
        losses,
        last_update_times,
        accum_times,
        checkpoint_count,
        target_duration,
    );
    let n_returns = valid_days;

    // Verify signals merkle inclusion
    let mut all_verified = true;
    for i in 0..MAX_SIGNALS {
        if (i as u32) < signals_count {
            let signal_hash = hash_signal(signals[i]);
            let verified = merkle_inclusion_check(
                signal_hash,
                signals_merkle_root,
                path_elements[i],
                path_indices[i],
            );
            all_verified = all_verified & verified;
        }
    }
    assert(all_verified);

    // Verify returns merkle root
    let mut leaves = [0; MAX_RETURNS];
    for i in 0..MAX_RETURNS {
        if (i as u32) < n_returns {
            leaves[i] = hash_return(log_returns[i]);
        }
    }
    let computed_returns_root = build_merkle_root(leaves, n_returns);
    assert(computed_returns_root == returns_merkle_root);

    // Calculate portfolio metrics
    let mut returns_array = [0; ARRAY_SIZE];
    for i in 0..MAX_DAYS {
        if (i as u32) < n_returns {
            returns_array[i] = log_returns[i];
        }
    }

    let sh = sharpe(returns_array, n_returns, RISK_FREE_RATE, false, false);
    let dmd = daily_max_drawdown(returns_array, n_returns);

    [sh as Field, dmd as Field]
}

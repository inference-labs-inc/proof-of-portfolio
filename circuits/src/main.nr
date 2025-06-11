use dep::std;

global SCALE: u64 = 10000;
global RISK_FREE_RATE: u64 = 500;
global MIN_DRAWDOWN: u64 = 100;
global MIN_VOLATILITY: u64 = 100;
global MIN_DOWNSIDE_DEVIATION: u64 = 100;
global MAX_DRAWDOWN_THRESHOLD: u64 = 1000;
global MAX_SIGNALS: u32 = 8;
global MERKLE_DEPTH: u32 = 4;

struct TradingSignal {
    miner_hotkey: [Field; 2],
    trade_pair_id: Field,
    order_type: Field,
    leverage_scaled: Field,
    price_scaled: Field,
    processed_ms: Field,
    order_uuid: [Field; 2],
    position_uuid: [Field; 2],
    src: Field,
}

unconstrained fn compute_sqrt(n: u64) -> u64 {
    if n <= 1 {
        n
    } else if n <= 3 {
        1
    } else if n <= 8 {
        2
    } else if n <= 15 {
        3
    } else {
        // Simple but effective initial guess
        let mut x = if n < 100 {
            n / 3
        } else if n < 10000 {
            n / 10
        } else {
            n / 100
        };

        // Ensure we start with at least 1
        if x == 0 {
            x = 1;
        }

        // Newton's method with early convergence
        let mut prev = 0;
        for _ in 0..15 {
            if x != prev {
                if x > 0 {
                    prev = x;
                    x = (x + n / x) / 2;
                }
            }
        }

        x
    }
}

fn verified_sqrt(n: u64) -> u64 {
    // Safety: Result is verified with mathematical constraints below
    // This comes from the Noir office hours call.
    let sqrt_result = unsafe { compute_sqrt(n) };

    assert(sqrt_result * sqrt_result <= n);
    assert((sqrt_result + 1) * (sqrt_result + 1) > n);

    sqrt_result
}

fn hash_signal(signal: TradingSignal) -> Field {
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

fn merkle_inclusion_check(
    leaf: Field,
    merkle_root: Field,
    path_elements: [Field; MERKLE_DEPTH],
    path_indices: [Field; MERKLE_DEPTH],
) -> bool {
    let mut current_hash = leaf;

    for i in 0..MERKLE_DEPTH {
        let path_element = path_elements[i];
        let is_right = path_indices[i];
        let hash_inputs = if is_right == 1 {
            [path_element, current_hash]
        } else {
            [current_hash, path_element]
        };
        current_hash = std::hash::pedersen_hash(hash_inputs);
    }

    current_hash == merkle_root
}

fn extract_returns_from_signals(
    signals: [TradingSignal; MAX_SIGNALS],
    n_signals: u32,
) -> ([i64; MAX_SIGNALS], u32) {
    let mut returns: [i64; MAX_SIGNALS] = [0; MAX_SIGNALS];
    let mut return_count = 0;

    let mut position_open = false;
    let mut entry_price: Field = 0;
    let mut leverage: Field = 1;

    for i in 0..MAX_SIGNALS {
        if (i as u32) < n_signals {
            let signal = signals[i];
            if signal.order_type == 1 {
                entry_price = signal.price_scaled;
                leverage = signal.leverage_scaled;
                position_open = true;
            } else if signal.order_type == 2 {
                if position_open {
                    let exit_price = signal.price_scaled;
                    let safe_entry_price = if entry_price == 0 { 1 } else { entry_price };
                    let price_diff = (exit_price as i64) - (entry_price as i64);
                    let return_value =
                        (price_diff * (leverage as i64) * 10000) / (safe_entry_price as i64);

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

fn calculate_calmar_ratio(returns: [i64; MAX_SIGNALS], n_returns: u32, max_drawdown: u64) -> u64 {
    if n_returns == 0 {
        0
    } else {
        let mut sum: i64 = 0;
        for i in 0..MAX_SIGNALS {
            if (i as u32) < n_returns {
                sum = sum + returns[i];
            }
        }

        let annualized_return = ((sum as u64) * 365 * SCALE) / (n_returns as u64);
        let excess_return = if annualized_return > RISK_FREE_RATE * SCALE {
            annualized_return - RISK_FREE_RATE * SCALE
        } else {
            0
        };

        let safe_drawdown = if max_drawdown < MIN_DRAWDOWN {
            MIN_DRAWDOWN
        } else {
            max_drawdown
        };

        excess_return / safe_drawdown
    }
}

fn calculate_sharpe_ratio(returns: [i64; MAX_SIGNALS], n_returns: u32) -> u64 {
    let result = if n_returns == 0 {
        0
    } else {
        // Calculate mean
        let mut sum: i64 = 0;
        for i in 0..MAX_SIGNALS {
            if (i as u32) < n_returns {
                sum = sum + returns[i];
            }
        }
        let mean = sum / (n_returns as i64);

        // Calculate variance
        let mut variance_sum: u64 = 0;
        for i in 0..MAX_SIGNALS {
            if (i as u32) < n_returns {
                let diff = returns[i] - mean;
                variance_sum = variance_sum + ((diff * diff) as u64);
            }
        }
        let variance = variance_sum / (n_returns as u64);

        // Annualized return
        let annualized_return = ((sum as u64) * 365 * SCALE) / (n_returns as u64);
        let excess_return = if annualized_return > RISK_FREE_RATE * SCALE {
            annualized_return - RISK_FREE_RATE * SCALE
        } else {
            0
        };

        // Annualized volatility
        // Safety: The n_returns check above ensures we don't divide by zero.
        let annualized_volatility =
            verified_sqrt((variance * 365 * SCALE * SCALE) / (n_returns as u64));
        let safe_volatility = if annualized_volatility < MIN_VOLATILITY * SCALE {
            MIN_VOLATILITY * SCALE
        } else {
            annualized_volatility
        };

        excess_return / safe_volatility
    };

    result
}

fn calculate_omega_ratio(returns: [i64; MAX_SIGNALS], n_returns: u32) -> u64 {
    let mut positive_sum: u64 = 0;
    let mut negative_sum: u64 = 0;

    for i in 0..MAX_SIGNALS {
        if (i as u32) < n_returns {
            if returns[i] > 0 {
                positive_sum = positive_sum + (returns[i] as u64);
            } else if returns[i] < 0 {
                negative_sum = negative_sum + ((-returns[i]) as u64);
            }
        }
    }

    let safe_negative_sum = if negative_sum < MIN_DRAWDOWN {
        MIN_DRAWDOWN
    } else {
        negative_sum
    };

    (positive_sum * SCALE) / safe_negative_sum
}

fn calculate_sortino_ratio(returns: [i64; MAX_SIGNALS], n_returns: u32) -> u64 {
    if n_returns == 0 {
        0
    } else {
        // Calculate mean
        let mut sum: i64 = 0;
        for i in 0..MAX_SIGNALS {
            if (i as u32) < n_returns {
                sum = sum + returns[i];
            }
        }

        // Calculate downside variance (only negative returns)
        let mut downside_variance_sum: u64 = 0;
        let mut negative_count: u32 = 0;

        for i in 0..MAX_SIGNALS {
            if (i as u32) < n_returns {
                if returns[i] < 0 {
                    let neg_return = returns[i];
                    downside_variance_sum =
                        downside_variance_sum + ((neg_return * neg_return) as u64);
                    negative_count = negative_count + 1;
                }
            }
        }

        let downside_variance = if negative_count > 0 {
            downside_variance_sum / (negative_count as u64)
        } else {
            1
        };

        // Annualized return
        let annualized_return = ((sum as u64) * 365 * SCALE) / (n_returns as u64);
        let excess_return = if annualized_return > RISK_FREE_RATE * SCALE {
            annualized_return - RISK_FREE_RATE * SCALE
        } else {
            0
        };

        // Annualized downside deviation
        let annualized_downside_deviation = verified_sqrt(
            (downside_variance * 365 * SCALE * SCALE) / (n_returns as u64),
        );
        let safe_downside_deviation = if annualized_downside_deviation
            < MIN_DOWNSIDE_DEVIATION * SCALE {
            MIN_DOWNSIDE_DEVIATION * SCALE
        } else {
            annualized_downside_deviation
        };

        excess_return / safe_downside_deviation
    }
}

fn calculate_statistical_confidence(returns: [i64; MAX_SIGNALS], n_returns: u32) -> u64 {
    if n_returns == 0 {
        0
    } else {
        // Calculate mean
        let mut sum: i64 = 0;
        for i in 0..MAX_SIGNALS {
            if (i as u32) < n_returns {
                sum = sum + returns[i];
            }
        }
        let mean = sum / (n_returns as i64);

        // Calculate variance
        let mut variance_sum: u64 = 0;
        for i in 0..MAX_SIGNALS {
            if (i as u32) < n_returns {
                let diff = returns[i] - mean;
                variance_sum = variance_sum + ((diff * diff) as u64);
            }
        }
        let variance = variance_sum / (n_returns as u64);

        // Calculate t-statistic: t = (mean - 0) / (std_dev / sqrt(n))
        let std_dev = verified_sqrt(variance);
        let standard_error = (std_dev * SCALE) / verified_sqrt(n_returns as u64);

        let result = if standard_error == 0 {
            SCALE
        } else {
            let t_statistic = ((mean as u64) * SCALE) / standard_error;
            let max_t_stat = 10 * SCALE;

            if t_statistic > max_t_stat {
                SCALE
            } else {
                (t_statistic * SCALE) / max_t_stat
            }
        };

        result
    }
}

fn calculate_miner_score(
    calmar_ratio: u64,
    sharpe_ratio: u64,
    omega_ratio: u64,
    sortino_ratio: u64,
    statistical_confidence: u64,
    max_drawdown: u64,
    risk_profile_penalty: u64,
) -> u64 {
    let score = if max_drawdown > MAX_DRAWDOWN_THRESHOLD {
        0
    } else {
        let weight = 2000;
        let base_score = (weight * calmar_ratio) / SCALE
            + (weight * sharpe_ratio) / SCALE
            + (weight * omega_ratio) / SCALE
            + (weight * sortino_ratio) / SCALE
            + (weight * statistical_confidence) / SCALE;

        let penalty_factor = SCALE - risk_profile_penalty;
        (base_score * penalty_factor) / SCALE
    };

    score
}

fn main(
    signals: [TradingSignal; MAX_SIGNALS],
    n_signals: u32,
    path_elements: pub [[Field; MERKLE_DEPTH]; MAX_SIGNALS],
    path_indices: pub [[Field; MERKLE_DEPTH]; MAX_SIGNALS],
    merkle_root: pub Field,
    max_drawdown: pub u64,
    risk_profile_penalty: pub u64,
) -> pub (u64, bool) {
    let mut all_verified = true;

    for i in 0..MAX_SIGNALS {
        if (i as u32) < n_signals {
            if signals[i].trade_pair_id != 0 {
                let signal_hash = hash_signal(signals[i]);
                let verified = merkle_inclusion_check(
                    signal_hash,
                    merkle_root,
                    path_elements[i],
                    path_indices[i],
                );
                all_verified = all_verified & verified;
            }
        }
    }

    let (returns, n_returns) = extract_returns_from_signals(signals, n_signals);

    let calmar_ratio = calculate_calmar_ratio(returns, n_returns, max_drawdown);
    let sharpe_ratio = calculate_sharpe_ratio(returns, n_returns);
    let omega_ratio = calculate_omega_ratio(returns, n_returns);
    let sortino_ratio = calculate_sortino_ratio(returns, n_returns);
    let statistical_confidence = calculate_statistical_confidence(returns, n_returns);

    let score = calculate_miner_score(
        calmar_ratio,
        sharpe_ratio,
        omega_ratio,
        sortino_ratio,
        statistical_confidence,
        max_drawdown,
        risk_profile_penalty,
    );

    (score, all_verified)
}

#[test]
fn test_full_circuit() {
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
        miner_hotkey: [1, 2],
        trade_pair_id: 1,
        order_type: 1,
        leverage_scaled: 2,
        price_scaled: 100000,
        processed_ms: 1234567890,
        order_uuid: [1, 1],
        position_uuid: [1, 1],
        src: 1,
    };

    signals[1] = TradingSignal {
        miner_hotkey: [1, 2],
        trade_pair_id: 1,
        order_type: 2,
        leverage_scaled: 2,
        price_scaled: 105000,
        processed_ms: 1234567900,
        order_uuid: [2, 2],
        position_uuid: [1, 1],
        src: 1,
    };

    let path_elements: [[Field; MERKLE_DEPTH]; MAX_SIGNALS] = [[0; MERKLE_DEPTH]; MAX_SIGNALS];
    let path_indices: [[Field; MERKLE_DEPTH]; MAX_SIGNALS] = [[0; MERKLE_DEPTH]; MAX_SIGNALS];

    let (score, verified) = main(signals, 2, path_elements, path_indices, 0, 300, 1000);

    assert(score > 0);
    assert(!verified);
}

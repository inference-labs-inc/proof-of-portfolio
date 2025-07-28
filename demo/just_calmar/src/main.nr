global ARRAY_SIZE: u32 = 120;
global CALMAR_NOCONFIDENCE_VALUE: i64 = -100;
global STATISTICAL_CONFIDENCE_MINIMUM_N: u32 = 30;
global SCALE: i64 = 10_000_000;

fn exp_decay_scaled(neg_x_scaled: i64) -> i64 {
    let scale: i64 = 100000;
    let x_pow_2 = neg_x_scaled * neg_x_scaled;
    let x_pow_3 = x_pow_2 * neg_x_scaled;

    let term1 = neg_x_scaled;
    let term2 = x_pow_2 / (2 * scale);
    let term3 = x_pow_3 / (6 * scale * scale);
    let term4 = (x_pow_3 * neg_x_scaled) / (24 * scale * scale * scale);

    scale + term1 + term2 + term3 + term4
}

pub fn weighting_distribution(actual_len: u32) -> [i64; ARRAY_SIZE] {
    let mut weights = [0; ARRAY_SIZE];
    let max_weight: i64 = 100000;
    let min_weight: i64 = 40000;
    let decay_rate: i64 = 8000;
    let weight_range = max_weight - min_weight;
    let scale: i64 = 100000;

    for i in 0..ARRAY_SIZE {
        if (i as u32) < actual_len {
            let neg_x_scaled = -decay_rate * (i as i64);
            let exp_val_scaled = exp_decay_scaled(neg_x_scaled);

            let weighted_val = (weight_range * exp_val_scaled) / scale;
            weights[actual_len - 1 - i] = min_weight + weighted_val;
        }
    }

    weights
}

pub fn average(log_returns: [i64; ARRAY_SIZE], actual_len: u32, use_weighting: bool) -> i64 {
    let mut result = 0;
    if actual_len > 0 {
        if use_weighting {
            let weights = weighting_distribution(actual_len);
            let mut weighted_sum: i64 = 0;
            let mut sum_of_weights: i64 = 0;

            for i in 0..ARRAY_SIZE {
                if (i as u32) < actual_len {
                    weighted_sum += log_returns[i] * weights[i];
                    sum_of_weights += weights[i];
                }
            }
            if sum_of_weights != 0 {
                result = weighted_sum / sum_of_weights;
            }
        } else {
            let mut sum: i64 = 0;
            for i in 0..ARRAY_SIZE {
                if (i as u32) < actual_len {
                    sum += log_returns[i];
                }
            }
            result = sum / (actual_len as i64);
        }
    }
    result
}

pub fn annualized_excess_return(
    log_returns: [i64; ARRAY_SIZE],
    actual_len: u32,
    risk_free_rate: i64,
    use_weighting: bool,
) -> i64 {
    let result = if actual_len == 0 {
        0
    } else {
        let avg_daily_return = average(log_returns, actual_len, use_weighting);
        let annualized_return = avg_daily_return * 365;
        annualized_return - risk_free_rate
    };
    result
}

fn daily_max_drawdown(log_returns: [i64; ARRAY_SIZE], actual_len: u32) -> i64 {
    let mut max_drawdown = 0;

    if actual_len > 0 {
        let mut cumulative_log_returns = [0; ARRAY_SIZE];
        let mut current_sum: i64 = 0;
        for i in 0..ARRAY_SIZE {
            if (i as u32) < actual_len {
                current_sum += log_returns[i];
                cumulative_log_returns[i] = current_sum;
            }
        }

        let mut running_max_log = [0; ARRAY_SIZE];
        let mut current_max: i64 = -9223372036854775807;
        for i in 0..ARRAY_SIZE {
            if (i as u32) < actual_len {
                if cumulative_log_returns[i] > current_max {
                    current_max = cumulative_log_returns[i];
                }
                running_max_log[i] = current_max;
            }
        }

        for i in 0..ARRAY_SIZE {
            if (i as u32) < actual_len {
                let drawdown_log = cumulative_log_returns[i] - running_max_log[i];
                let drawdown = SCALE - exp_decay_scaled(drawdown_log);
                if drawdown > max_drawdown {
                    max_drawdown = drawdown;
                }
            }
        }
    }
    max_drawdown
}

pub fn calmar(
    log_returns: [i64; ARRAY_SIZE],
    actual_len: u32,
    risk_free_rate: i64,
    use_weighting: bool,
) -> i64 {
    if actual_len < STATISTICAL_CONFIDENCE_MINIMUM_N {
        CALMAR_NOCONFIDENCE_VALUE
    } else {
        let ann_excess_return = annualized_excess_return(log_returns, actual_len, risk_free_rate, use_weighting);
        let max_drawdown = daily_max_drawdown(log_returns, actual_len);

        if max_drawdown == 0 {
            0
        } else {
            (ann_excess_return * SCALE) / max_drawdown
        }
    }
}

pub fn main(
    log_returns: [i64; ARRAY_SIZE],
    actual_len: u32,
    risk_free_rate: i64,
    use_weighting: bool,
    bypass_confidence: bool,
) -> pub i64 {
    let result = if !bypass_confidence & (actual_len < STATISTICAL_CONFIDENCE_MINIMUM_N) {
        CALMAR_NOCONFIDENCE_VALUE
    } else {
        calmar(log_returns, actual_len, risk_free_rate, use_weighting)
    };
    result
}




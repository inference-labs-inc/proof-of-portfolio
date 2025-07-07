use crate::utils::constants::ARRAY_SIZE;
use crate::utils::sqrt::sqrt;
use crate::utils::weighting_distribution::weighting_distribution;

global SHARPE_NOCONFIDENCE_VALUE: i64 = -100;
global SHARPE_STDDEV_MINIMUM: i64 = 10000;
global STATISTICAL_CONFIDENCE_MINIMUM_N: u32 = 60;

global SCALE: i64 = 1_000_000;
global VOLATILITY_SCALE: i64 = 10_000;



pub fn average(daily_returns: [i64; ARRAY_SIZE], actual_len: u32, use_weighting: bool) -> i64 {
    let mut result = 0;
    if actual_len > 0 {
        if use_weighting {
            let weights = weighting_distribution(actual_len);
            let mut weighted_sum: i64 = 0;
            let mut sum_of_weights: i64 = 0;

            for i in 0..ARRAY_SIZE {
                if (i as u32) < actual_len {
                    weighted_sum += (daily_returns[i] / 1000) * weights[i];
                    sum_of_weights += weights[i];
                }
            }
            if sum_of_weights != 0 {
                result = (weighted_sum / sum_of_weights) * 1000;
            }
        } else {
            let mut sum: i64 = 0;
            for i in 0..ARRAY_SIZE {
                if (i as u32) < actual_len {
                    sum += daily_returns[i];
                }
            }
            result = sum / (actual_len as i64);
        }
    }
    result
}

pub fn variance(
    daily_returns: [i64; ARRAY_SIZE],
    actual_len: u32,
    ddof: u32,
    use_weighting: bool,
) -> i64 {
    let mut variance = 0;
    let mut proceed = false;
    if use_weighting {
        if actual_len >= 2 {
            proceed = true;
        }
    } else {
        if actual_len > ddof {
            proceed = true;
        }
    }

    if proceed {
        let mean = average(daily_returns, actual_len, use_weighting);
        if use_weighting {
            let weights = weighting_distribution(actual_len);
            let mut weighted_sum_sq_diff: i64 = 0;
            let mut sum_of_weights: i64 = 0;

            for i in 0..ARRAY_SIZE {
                if (i as u32) < actual_len {
                    let diff = daily_returns[i] - mean;
                    let scaled_diff = diff / 1000;
                    weighted_sum_sq_diff += (scaled_diff * scaled_diff) * weights[i];
                    sum_of_weights += weights[i];
                }
            }

            if sum_of_weights != 0 {
                variance = weighted_sum_sq_diff / sum_of_weights;
            }
        } else {
            let mut sum_sq_diff: i64 = 0;

            for i in 0..ARRAY_SIZE {
                if (i as u32) < actual_len {
                    let diff = daily_returns[i] - mean;
                    let scaled_diff = diff / 1000;
                    sum_sq_diff += scaled_diff * scaled_diff;
                }
            }
            variance = sum_sq_diff / ((actual_len - ddof) as i64);
        }
    }
    variance
}

pub fn annualized_volatility(
    daily_returns: [i64; ARRAY_SIZE],
    actual_len: u32,
    use_weighting: bool,
) -> i64 {
    let result = if actual_len < 2 {
        SCALE
    } else {
        let daily_variance = variance(daily_returns, actual_len, 1, use_weighting);
        let annualized_variance = daily_variance * 365;
        sqrt(annualized_variance as u64) as i64 * 1000
    };
    result
}

pub fn annualized_excess_return(
    daily_returns: [i64; ARRAY_SIZE],
    actual_len: u32,
    risk_free_rate: i64,
    use_weighting: bool,
) -> i64 {
    let result = if actual_len == 0 {
        0
    } else {
        let avg_daily_return = average(daily_returns, actual_len, use_weighting);
        let annualized_return = avg_daily_return * 365;
        annualized_return - risk_free_rate
    };
    result
}

pub fn sharpe_ratio(
    daily_returns: [i64; ARRAY_SIZE],
    actual_len: u32,
    risk_free_rate: i64,
    use_weighting: bool,
    bypass_confidence: bool,
) -> i64 {
    let result = if !bypass_confidence & actual_len < STATISTICAL_CONFIDENCE_MINIMUM_N {
        SHARPE_NOCONFIDENCE_VALUE
    } else {
        let excess_return =
            annualized_excess_return(daily_returns, actual_len, risk_free_rate, use_weighting);
        let volatility = annualized_volatility(daily_returns, actual_len, use_weighting);
        let effective_volatility = if volatility < SHARPE_STDDEV_MINIMUM {
            SHARPE_STDDEV_MINIMUM
        } else {
            volatility
        };

        (excess_return * VOLATILITY_SCALE) / effective_volatility
    };
    result
}

pub fn max_drawdown(portfolio_values: [i64; ARRAY_SIZE], actual_len: u32) -> i64 {
    let result = if actual_len < 2 {
        0
    } else {
        let mut max_drawdown: i64 = 0;
        let mut running_max: i64 = portfolio_values[0];

        for i in 1..ARRAY_SIZE {
            if (i as u32) < actual_len {
                let current_value = portfolio_values[i];

                if current_value > running_max {
                    running_max = current_value;
                }

                if running_max != 0 {
                    let drawdown_numerator = running_max - current_value;
                    let drawdown_fraction = (drawdown_numerator * SCALE) / running_max; // Scale by 1M for precision

                    if drawdown_fraction > max_drawdown {
                        max_drawdown = drawdown_fraction;
                    }
                }
            }
        }

        max_drawdown
    };

    result
}

pub fn annualized_downside_volatility(
    daily_returns: [i64; ARRAY_SIZE],
    actual_len: u32,
    daily_risk_free_rate: i64,
    use_weighting: bool,
) -> i64 {
    let mut downside_returns = [0; ARRAY_SIZE];
    let mut n_downside = 0;

    // 1. Filter for downside returns (returns below the target rate)
    for i in 0..ARRAY_SIZE {
        if (i as u32) < actual_len {
            if daily_returns[i] < daily_risk_free_rate {
                downside_returns[n_downside] = daily_returns[i];
                n_downside = n_downside + 1;
            }
        }
    }

    let volatility = if n_downside < 2 {
        SCALE
    } else {
        let downside_variance = variance(downside_returns, n_downside, 0, use_weighting);

        let annualized_downside_variance = downside_variance * 365;

        sqrt(annualized_downside_variance as u64) as i64 * 1000
    };
    volatility
}

pub fn sortino_ratio(
    daily_returns: [i64; ARRAY_SIZE],
    actual_len: u32,
    risk_free_rate: i64,
    use_weighting: bool,
) -> i64 {
    let sortino_ratio = if actual_len < 2 {
        0
    } else {
        let excess_return =
            annualized_excess_return(daily_returns, actual_len, risk_free_rate, use_weighting);
        let daily_risk_free_rate = risk_free_rate / 365;
        let downside_vol = annualized_downside_volatility(
            daily_returns,
            actual_len,
            daily_risk_free_rate,
            use_weighting,
        );

        let min_volatility: i64 = 10000; // 0.01 * 1e6
        let effective_volatility = if downside_vol < min_volatility {
            min_volatility
        } else {
            downside_vol
        };

        if effective_volatility == 0 {
            0
        } else {
            (excess_return * SCALE) / effective_volatility
        }
    };
    sortino_ratio
}

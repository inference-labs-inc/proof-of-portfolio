use crate::utils::{ann_excess_return::ann_excess_return, constants::ARRAY_SIZE, sqrt::sqrt};

pub fn sortino(log_returns: [i64; ARRAY_SIZE], actual_len: u32, RISK_FREE_RATE: i64) -> i64 {
    let excess_return = ann_excess_return(log_returns, actual_len, RISK_FREE_RATE);

    let mut downside_variance_sum: u64 = 0;
    let mut negative_count: u32 = 0;

    for i in 0..ARRAY_SIZE {
        if (i as u32) < actual_len {
            if log_returns[i] < 0 {
                let neg_return = log_returns[i];
                downside_variance_sum = downside_variance_sum + ((neg_return * neg_return) as u64);
                negative_count = negative_count + 1;
            }
        }
    }

    if negative_count > 0 {
        let downside_variance = downside_variance_sum / (negative_count as u64);
        let downside_volatility = sqrt(downside_variance * 365) as i64;

        if downside_volatility > 100 {
            (excess_return * 100000000) / downside_volatility
        } else {
            0
        }
    } else {
        0
    }
}

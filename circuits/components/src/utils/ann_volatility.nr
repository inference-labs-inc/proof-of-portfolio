use crate::utils::{constants::ARRAY_SIZE, sqrt::sqrt, variance::variance};

pub fn ann_volatility(log_returns: [i64; ARRAY_SIZE], actual_len: u32, ddof: u32) -> i64 {
    let var = variance(log_returns, actual_len, ddof);
    let ann_var = var * 365;
    if ann_var > 0 {
        sqrt(ann_var as u64) as i64
    } else {
        0
    }
}

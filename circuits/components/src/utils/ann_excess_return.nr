use crate::utils::{average::average, constants::ARRAY_SIZE};

pub fn ann_excess_return(
    log_returns: [i64; ARRAY_SIZE],
    actual_len: u32,
    RISK_FREE_RATE: i64,
) -> i64 {
    let avg = average(log_returns, actual_len);
    let annualized = avg * 365;
    annualized - (RISK_FREE_RATE as i64)
}

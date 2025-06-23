use crate::utils::{
    ann_excess_return::ann_excess_return, ann_volatility::ann_volatility, constants::ARRAY_SIZE,
};

pub fn sharpe(log_returns: [i64; ARRAY_SIZE], actual_len: u32, RISK_FREE_RATE: i64) -> i64 {
    let excess_return = ann_excess_return(log_returns, actual_len, RISK_FREE_RATE);
    let volatility = ann_volatility(log_returns, actual_len, 1);

    if volatility > 100 {
        (excess_return * 1000000) / volatility
    } else {
        0
    }
}

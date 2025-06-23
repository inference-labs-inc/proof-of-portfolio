use crate::utils::{ann_excess_return::ann_excess_return, constants::ARRAY_SIZE};
use super::drawdown::daily_max_drawdown;

pub fn calmar(log_returns: [i64; ARRAY_SIZE], actual_len: u32, RISK_FREE_RATE: i64) -> i64 {
    if actual_len < 30 {
        0
    } else {
        let ann_excess_return = ann_excess_return(log_returns, actual_len, RISK_FREE_RATE);
        let max_drawdown = daily_max_drawdown(log_returns, actual_len);

        if max_drawdown == 0 {
            0
        } else {
            (ann_excess_return * 1000000) / max_drawdown
        }
    }
}

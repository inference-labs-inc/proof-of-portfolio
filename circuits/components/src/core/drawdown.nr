use crate::utils::constants::ARRAY_SIZE;

pub fn daily_max_drawdown(log_returns: [i64; ARRAY_SIZE], actual_len: u32) -> i64 {
    let mut max_drawdown: i64 = 0;
    let mut cumulative: i64 = 0;
    let mut peak: i64 = 0;

    for i in 0..ARRAY_SIZE {
        if (i as u32) < actual_len {
            cumulative = cumulative + log_returns[i];
            if cumulative > peak {
                peak = cumulative;
            }
            let drawdown = peak - cumulative;
            if drawdown > max_drawdown {
                max_drawdown = drawdown;
            }
        }
    }

    max_drawdown
}

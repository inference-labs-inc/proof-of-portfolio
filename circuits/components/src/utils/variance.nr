use crate::utils::{average::average, constants::ARRAY_SIZE};

pub fn variance(log_returns: [i64; ARRAY_SIZE], actual_len: u32, ddof: u32) -> i64 {
    let avg = average(log_returns, actual_len);
    let mut variance_sum: u64 = 0;

    for i in 0..ARRAY_SIZE {
        if (i as u32) < actual_len {
            let diff = log_returns[i] - avg;
            variance_sum = variance_sum + ((diff * diff) as u64);
        }
    }

    let denominator = if (ddof > 0) & (actual_len > ddof) {
        actual_len - ddof
    } else {
        actual_len
    };

    (variance_sum / (denominator as u64)) as i64
}

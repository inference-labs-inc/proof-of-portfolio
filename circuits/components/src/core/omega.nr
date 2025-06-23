use crate::utils::constants::ARRAY_SIZE;

pub fn omega(log_returns: [i64; ARRAY_SIZE], actual_len: u32) -> i64 {
    let mut positive_sum: u64 = 0;
    let mut negative_sum: u64 = 0;

    for i in 0..ARRAY_SIZE {
        if (i as u32) < actual_len {
            if log_returns[i] > 0 {
                positive_sum = positive_sum + (log_returns[i] as u64);
            } else if log_returns[i] < 0 {
                negative_sum = negative_sum + ((-log_returns[i]) as u64);
            }
        }
    }

    if negative_sum > 0 {
        ((positive_sum * 10000000) / negative_sum) as i64
    } else {
        10000000
    }
}

use crate::utils::constants::ARRAY_SIZE;

pub fn average(log_returns: [i64; ARRAY_SIZE], actual_len: u32) -> i64 {
    let mut sum: i64 = 0;
    for i in 0..ARRAY_SIZE {
        if (i as u32) < actual_len {
            sum = sum + log_returns[i];
        }
    }
    sum / (actual_len as i64)
}

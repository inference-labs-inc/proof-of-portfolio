use crate::utils::{average::average, constants::ARRAY_SIZE, sqrt::sqrt, variance::variance};

pub fn statistical_confidence(log_returns: [i64; ARRAY_SIZE], actual_len: u32) -> i64 {
    if actual_len < 2 {
        0
    } else {
        let avg = average(log_returns, actual_len);
        let var = variance(log_returns, actual_len, 1);

        if var <= 0 {
            0
        } else {
            let std_dev = sqrt(var as u64) as i64;
            let standard_error = (std_dev * 1000000) / sqrt(actual_len as u64) as i64;

            if standard_error == 0 {
                1000000
            } else {
                let t_statistic = (avg * 1000000) / standard_error;
                if t_statistic > 10000000 {
                    1000000
                } else {
                    t_statistic / 10
                }
            }
        }
    }
}

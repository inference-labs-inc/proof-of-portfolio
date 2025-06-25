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

#[test]
fn test_variance_same_values() {
    let mut returns = [0; ARRAY_SIZE];
    for i in 0..5 {
        returns[i] = 100;
    }

    let result = variance(returns, 5, 1);
    assert(result == 0);
}

#[test]
fn test_variance_different_values() {
    let mut returns = [0; ARRAY_SIZE];
    returns[0] = 100;
    returns[1] = 200;
    returns[2] = 300;

    let result = variance(returns, 3, 1);
    assert(result > 0);
}

#[test]
fn test_variance_with_ddof_zero() {
    let mut returns = [0; ARRAY_SIZE];
    returns[0] = 100;
    returns[1] = 200;
    returns[2] = 300;

    let result_ddof_0 = variance(returns, 3, 0);
    let result_ddof_1 = variance(returns, 3, 1);
    assert(result_ddof_0 != result_ddof_1);
}

#[test]
fn test_variance_single_value() {
    let mut returns = [0; ARRAY_SIZE];
    returns[0] = 500;

    let result = variance(returns, 1, 0);
    assert(result == 0);
}

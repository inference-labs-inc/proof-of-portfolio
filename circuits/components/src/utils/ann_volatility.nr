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

#[test]
fn test_ann_volatility_zero_variance() {
    let mut returns = [0; ARRAY_SIZE];
    for i in 0..5 {
        returns[i] = 100;
    }

    let result = ann_volatility(returns, 5, 1);
    assert(result == 0);
}

#[test]
fn test_ann_volatility_positive_variance() {
    let mut returns = [0; ARRAY_SIZE];
    returns[0] = 100;
    returns[1] = 200;
    returns[2] = 300;
    returns[3] = 400;
    returns[4] = 500;

    let result = ann_volatility(returns, 5, 1);
    assert(result > 0);
}

#[test]
fn test_ann_volatility_ddof_zero() {
    let mut returns = [0; ARRAY_SIZE];
    returns[0] = 100;
    returns[1] = 200;
    returns[2] = 300;

    let result_ddof_0 = ann_volatility(returns, 3, 0);
    let result_ddof_1 = ann_volatility(returns, 3, 1);
    assert(result_ddof_0 != result_ddof_1);
}

#[test]
fn test_ann_volatility_single_value() {
    let mut returns = [0; ARRAY_SIZE];
    returns[0] = 500;

    let result = ann_volatility(returns, 1, 0);
    assert(result == 0);
}

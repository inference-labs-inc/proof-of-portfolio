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

#[test]
fn test_average_positive_numbers() {
    let mut returns = [0; ARRAY_SIZE];
    returns[0] = 100;
    returns[1] = 200;
    returns[2] = 300;

    let result = average(returns, 3);
    assert(result == 200);
}

#[test]
fn test_average_negative_numbers() {
    let mut returns = [0; ARRAY_SIZE];
    returns[0] = -100;
    returns[1] = -200;
    returns[2] = -300;

    let result = average(returns, 3);
    assert(result == -200);
}

#[test]
fn test_average_mixed_numbers() {
    let mut returns = [0; ARRAY_SIZE];
    returns[0] = 100;
    returns[1] = -200;
    returns[2] = 300;
    returns[3] = -400;

    let result = average(returns, 4);
    assert(result == -50);
}

#[test]
fn test_average_single_number() {
    let mut returns = [0; ARRAY_SIZE];
    returns[0] = 500;

    let result = average(returns, 1);
    assert(result == 500);
}

#[test]
fn test_average_zeros() {
    let mut returns = [0; ARRAY_SIZE];
    for i in 0..10 {
        returns[i] = 0;
    }

    let result = average(returns, 10);
    assert(result == 0);
}

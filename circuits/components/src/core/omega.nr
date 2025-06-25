use crate::utils::constants::{
    ARRAY_SIZE, OMEGA_LOSS_MINIMUM, OMEGA_NOCONFIDENCE_VALUE, OMEGA_SCALE_FACTOR,
    STATISTICAL_CONFIDENCE_MINIMUM_N,
};

pub fn omega(log_returns: [i64; ARRAY_SIZE], actual_len: u32) -> i64 {
    // Check minimum sample size for statistical confidence
    if actual_len < STATISTICAL_CONFIDENCE_MINIMUM_N {
        OMEGA_NOCONFIDENCE_VALUE
    } else {
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
            ((positive_sum * (OMEGA_SCALE_FACTOR as u64)) / negative_sum) as i64
        } else {
            // No negative returns - return maximum omega value
            OMEGA_SCALE_FACTOR
        }
    }
}

#[test]
fn test_omega_all_positive() {
    let mut returns = [0; ARRAY_SIZE];
    for i in 0..5 {
        returns[i] = 100;
    }

    let result = omega(returns, 5);
    assert(result == 10000000);
}

#[test]
fn test_omega_all_negative() {
    let mut returns = [0; ARRAY_SIZE];
    for i in 0..5 {
        returns[i] = -100;
    }

    let result = omega(returns, 5);
    assert(result == 0);
}

#[test]
fn test_omega_mixed_returns() {
    let mut returns = [0; ARRAY_SIZE];
    returns[0] = 1000;
    returns[1] = -500;
    returns[2] = 800;
    returns[3] = -300;

    let result = omega(returns, 4);
    assert(result == 22500000);
}

#[test]
fn test_omega_zero_returns() {
    let mut returns = [0; ARRAY_SIZE];
    for i in 0..5 {
        returns[i] = 0;
    }

    let result = omega(returns, 5);
    assert(result == 10000000);
}

use crate::utils::{average::average, constants::{ARRAY_SIZE, SCALE}};

pub fn variance(
    daily_returns: [i64; ARRAY_SIZE],
    actual_len: u32,
    ddof: u32,
    weights: [i64; ARRAY_SIZE],
    use_weighting: bool,
    sum_of_weights: i64,
) -> i64 {
    let mut variance = 0;
    let mut proceed = false;
    if use_weighting {
        if actual_len >= 2 {
            proceed = true;
        }
    } else {
        if actual_len > ddof {
            proceed = true;
        }
    }

    if proceed {
        let mean = average(
            daily_returns,
            actual_len,
            weights,
            use_weighting,
            sum_of_weights,
        );

        println(
            f"[VARIANCE] actual_len={actual_len}, use_weighting={use_weighting}, mean={mean}",
        );
        if use_weighting {
            let mut weighted_sum_sq_diff: i64 = 0;

            for i in 0..ARRAY_SIZE {
                if (i as u32) < actual_len {
                    let diff = daily_returns[i] - mean;
                    let sq_diff = diff * diff;
                    weighted_sum_sq_diff += sq_diff * weights[i] / SCALE;
                }
            }

            if sum_of_weights != 0 {
                variance = weighted_sum_sq_diff / sum_of_weights;
            }
        } else {
            let mut sum_sq_diff: i64 = 0;

            println(f"[VARIANCE] Starting variance calculation with mean={mean}");
            for i in 0..ARRAY_SIZE {
                if (i as u32) < actual_len {
                    let return_val = daily_returns[i];
                    let diff = return_val - mean;
                    let sq_diff = diff * diff;
                    println(
                        f"[VARIANCE] i={i}, return_val={return_val}, diff={diff}, sq_diff={sq_diff}",
                    );
                    sum_sq_diff += sq_diff;
                    println(f"[VARIANCE] sum_sq_diff now={sum_sq_diff}");
                }
            }

            let denominator = actual_len as i64;
            println(
                f"[VARIANCE] sum_sq_diff={sum_sq_diff}, denominator={denominator}",
            );
            variance = sum_sq_diff / denominator;
            println(
                f"[VARIANCE] Final variance calculation: {sum_sq_diff} / {denominator} = {variance}",
            );
        }
    }

    println(f"[VARIANCE] Final variance={variance}");
    variance
}

#[test]
fn test_variance_same_values() {
    let mut returns = [0; ARRAY_SIZE];
    for i in 0..5 {
        returns[i] = 100;
    }

    let weights = [100000; ARRAY_SIZE];
    let result = variance(returns, 5, 1, weights, false, 5);
    assert(result == 0);
}

#[test]
fn test_variance_different_values() {
    let mut returns = [0; ARRAY_SIZE];
    returns[0] = 100000;
    returns[1] = 200000;
    returns[2] = 300000;

    let weights = [100000; ARRAY_SIZE];
    let result = variance(returns, 3, 1, weights, false, 3);
    assert(result > 0);
}

#[test]
fn test_variance_with_ddof_zero() {
    let mut returns = [0; ARRAY_SIZE];
    returns[0] = 100;
    returns[1] = 200;
    returns[2] = 300;

    let weights = [100000; ARRAY_SIZE];
    let result_ddof_0: i64 = variance(returns, 3, 0, weights, false, 3);
    let result_ddof_1: i64 = variance(returns, 3, 1, weights, false, 3);
    assert(result_ddof_0 == result_ddof_1);
}

#[test]
fn test_variance_single_value() {
    let mut returns = [0; ARRAY_SIZE];
    returns[0] = 500;

    let weights = [100000; ARRAY_SIZE];
    let result = variance(returns, 1, 0, weights, false, 1);
    assert(result == 0);
}

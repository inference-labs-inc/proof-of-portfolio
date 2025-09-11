use crate::utils::{average::average, constants::{ARRAY_SIZE, SCALE}};

pub fn downside_variance(
    daily_returns: [i64; ARRAY_SIZE],
    actual_len: u32,
    ddof: u32,
    weights: [i64; ARRAY_SIZE],
    use_weighting: bool,
    daily_rf: i64,
) -> i64 {
    let mut downside_variance = 0;

    // First pass: collect downside returns and calculate downside average
    let mut downside_returns = [0; ARRAY_SIZE];
    let mut downside_weights = [0; ARRAY_SIZE];
    let mut downside_count = 0;
    let mut downside_sum_weights = 0;

    for i in 0..ARRAY_SIZE {
        if (i as u32) < actual_len {
            if daily_returns[i] < daily_rf {
                downside_returns[downside_count] = daily_returns[i];
                if use_weighting {
                    downside_weights[downside_count] = weights[i];
                    downside_sum_weights += weights[i];
                } else {
                    downside_weights[downside_count] = SCALE / 1000; // Equal weight
                    downside_sum_weights += SCALE / 1000;
                }
                downside_count += 1;
            }
        }
    }

    // If no downside returns, use high variance (will result in low ratio)
    if downside_count == 0 {
        downside_variance = SCALE * SCALE; // Very high variance
    } else {
        // Calculate downside average
        let downside_avg = average(
            downside_returns,
            downside_count,
            downside_weights,
            use_weighting,
            downside_sum_weights,
        );

        // Calculate variance of downside returns
        let mut proceed = false;
        if use_weighting {
            if downside_count >= 2 {
                proceed = true;
            }
        } else {
            if downside_count > ddof {
                proceed = true;
            }
        }

        if proceed {
            let mut sum_sq_diff = 0;

            if use_weighting {
                let mut sum_weights_sq = 0;
                for i in 0..ARRAY_SIZE {
                    if (i as u32) < downside_count {
                        let diff = downside_returns[i] - downside_avg;
                        let weighted_sq_diff = ((diff / 100) * (diff / 100) * downside_weights[i]) / (SCALE / 10000);
                        sum_sq_diff += weighted_sq_diff;
                        sum_weights_sq += (downside_weights[i] / 100 * downside_weights[i] / 100) * (SCALE / 10000);
                    }
                }

                let denominator = downside_sum_weights - (sum_weights_sq / downside_sum_weights);
                if denominator > 0 {
                    downside_variance = sum_sq_diff / denominator;
                } else {
                    downside_variance = SCALE;
                }
            } else {
                for i in 0..ARRAY_SIZE {
                    if (i as u32) < downside_count {
                        let diff = downside_returns[i] - downside_avg;
                        sum_sq_diff += ((diff / 100) * (diff / 100)) / (SCALE / 10000);
                    }
                }
                downside_variance = sum_sq_diff / ((downside_count - ddof) as i64);
            }
        } else {
            downside_variance = SCALE;
        }
    }

    downside_variance
}

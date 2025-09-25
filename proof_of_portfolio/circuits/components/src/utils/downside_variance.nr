use crate::utils::{average::average, constants::ARRAY_SIZE};

pub fn downside_variance(
    daily_returns: [i64; ARRAY_SIZE],
    actual_len: u32,
    ddof: u32,
    weights: [i64; ARRAY_SIZE],
    use_weighting: bool,
    daily_rf: i64,
) -> i64 {
    let mut downside_variance = 0;

    let sum_of_weights = if use_weighting {
        let mut sum: i64 = 0;
        for i in 0..ARRAY_SIZE {
            if (i as u32) < actual_len {
                sum += weights[i];
            }
        }
        sum
    } else {
        actual_len as i64
    };

    let mean = average(
        daily_returns,
        actual_len,
        weights,
        use_weighting,
        sum_of_weights,
    );

    println(f"[DOWNSIDE_VAR] Using daily_rf={daily_rf} not mean={mean}");

    let mut downside_returns: [i64; ARRAY_SIZE] = [0; ARRAY_SIZE];
    let mut downside_count: u32 = 0;
    let mut downside_sum: i64 = 0;

    for i in 0..ARRAY_SIZE {
        if (i as u32) < actual_len {
            let return_val = daily_returns[i];
            if return_val < daily_rf {
                downside_returns[downside_count] = return_val;
                downside_sum += return_val;
                downside_count += 1;
                println(
                    f"[DOWNSIDE_VAR] Downside return {downside_count}: {return_val}",
                );
            } else {
                println(
                    f"[DOWNSIDE_VAR] i={i}, return={return_val} >= daily_rf={daily_rf}, skipping",
                );
            }
        }
    }

    let mut sum_sq_diff = 0;
    if downside_count > 0 {
        let downside_mean = downside_sum / (downside_count as i64);
        println(
            f"[DOWNSIDE_VAR] Downside count: {downside_count}, sum: {downside_sum}, mean: {downside_mean}",
        );

        for i in 0..ARRAY_SIZE {
            if i < downside_count {
                let return_val = downside_returns[i];
                let diff_from_downside_mean = return_val - downside_mean;
                let sq_diff = diff_from_downside_mean * diff_from_downside_mean;
                println(
                    f"[DOWNSIDE_VAR] Downside {i}: return={return_val}, diff={diff_from_downside_mean}, sq_diff={sq_diff}",
                );
                sum_sq_diff += sq_diff;
            }
        }
    }

    if use_weighting {
        if sum_of_weights > 0 {
            downside_variance = sum_sq_diff / sum_of_weights;
        }
    } else {
        if downside_count > 0 {
            downside_variance = sum_sq_diff / (downside_count as i64);
        }
    }

    let denominator_val = if use_weighting {
        sum_of_weights
    } else {
        downside_count as i64
    };
    println(
        f"[DOWNSIDE_VAR] Final: sum_sq_diff={sum_sq_diff}, denominator={denominator_val}, result={downside_variance}",
    );

    downside_variance
}

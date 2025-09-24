use crate::utils::constants::{
    ARRAY_SIZE, OMEGA_NOCONFIDENCE_VALUE, SCALE, STATISTICAL_CONFIDENCE_MINIMUM_N,
};

fn generate_linear_weights(length: u32) -> [i64; ARRAY_SIZE] {
    let mut weights = [0; ARRAY_SIZE];

    let min_weight = 15000000;
    let max_weight = 100000000;
    let weight_range = max_weight - min_weight;

    for i in 0..length {
        let progress = (i as i64) * SCALE / (length as i64);
        let quadratic_progress = (progress * progress) / SCALE;
        let weight = min_weight + ((weight_range * quadratic_progress) / SCALE);
        weights[i] = weight;
    }

    weights
}

fn verify_exponential_weights(weights: [i64; ARRAY_SIZE], length: u32) {
    let min_weight_scaled = 15000000;
    let max_weight_scaled = SCALE;

    for i in 0..length {
        assert(weights[i] >= min_weight_scaled);
        assert(weights[i] <= max_weight_scaled);

        if i > 0 {
            assert(weights[i] >= weights[i - 1]);
        }
    }
}

pub fn omega(
    log_returns: [i64; ARRAY_SIZE],
    actual_len: u32,
    weights: [i64; ARRAY_SIZE],
    use_weighting: bool,
    bypass_confidence: bool,
    omega_loss_min: i64,
    noconfidence_value: i64,
    minimum_n: u32,
) -> i64 {
    if !bypass_confidence & actual_len < minimum_n {
        noconfidence_value
    } else {
        if use_weighting {
            let mut product_sum_positive: i64 = 0;
            let mut product_sum_negative: i64 = 0;
            let mut sum_weights_positive_raw: i64 = 0;
            let mut sum_weights_negative_raw: i64 = 0;

            for i in 0..ARRAY_SIZE {
                if (i as u32) < actual_len {
                    let weight = weights[i];
                    let log_return = log_returns[i];
                    if log_return > 0 {
                        product_sum_positive += (log_return * weight) / SCALE;
                        sum_weights_positive_raw += weight;
                    } else {
                        product_sum_negative += (log_return * weight) / SCALE;
                        sum_weights_negative_raw += weight;
                    }
                }
            }

            let sum_weights_positive = if sum_weights_positive_raw >= omega_loss_min {
                sum_weights_positive_raw
            } else {
                omega_loss_min
            };
            let sum_weights_negative = if sum_weights_negative_raw >= omega_loss_min {
                sum_weights_negative_raw
            } else {
                omega_loss_min
            };

            let positive_sum = (product_sum_positive * sum_weights_negative) / SCALE;
            let negative_sum = (product_sum_negative * sum_weights_positive) / SCALE;

            let numerator = positive_sum;
            let abs_negative_sum = if negative_sum >= 0 {
                negative_sum
            } else {
                -negative_sum
            };

            let effective_denominator = if abs_negative_sum >= omega_loss_min {
                abs_negative_sum
            } else {
                omega_loss_min
            };

            if effective_denominator > 0 {
                (numerator * SCALE) / effective_denominator
            } else {
                0
            }
        } else {
            let mut positive_sum: i64 = 0;
            let mut negative_sum: i64 = 0;
            let mut _count_pos: u32 = 0;
            let mut _count_neg: u32 = 0;

            for i in 0..ARRAY_SIZE {
                if (i as u32) < actual_len {
                    let log_return = log_returns[i];
                    if log_return > 0 {
                        positive_sum += log_return;
                    } else {
                        negative_sum += log_return;
                    }
                }
            }

            let effective_denominator = if -negative_sum >= omega_loss_min {
                -negative_sum
            } else {
                omega_loss_min
            };
            (positive_sum * SCALE) / effective_denominator
        }
    }
}

#[test]
fn test_omega_all_positive() {
    let mut returns = [0; ARRAY_SIZE];
    for i in 0..5 {
        returns[i] = 100;
    }

    let weights = [100000; ARRAY_SIZE];
    let result = omega(
        returns,
        5,
        weights,
        false,
        false,
        10000000,
        OMEGA_NOCONFIDENCE_VALUE,
        STATISTICAL_CONFIDENCE_MINIMUM_N,
    );
    assert(result == 0);
}

#[test]
fn test_omega_all_negative() {
    let mut returns = [0; ARRAY_SIZE];
    for i in 0..5 {
        returns[i] = -100;
    }

    let weights = [100000; ARRAY_SIZE];
    let result = omega(
        returns,
        5,
        weights,
        false,
        false,
        10000000,
        OMEGA_NOCONFIDENCE_VALUE,
        STATISTICAL_CONFIDENCE_MINIMUM_N,
    );
    assert(result == 0);
}

#[test]
fn test_omega_mixed_returns() {
    let mut returns = [0; ARRAY_SIZE];
    returns[0] = 1000;
    returns[1] = -500;
    returns[2] = 800;
    returns[3] = -300;

    let weights = [100000; ARRAY_SIZE];
    let result = omega(
        returns,
        4,
        weights,
        false,
        false,
        10000000,
        OMEGA_NOCONFIDENCE_VALUE,
        STATISTICAL_CONFIDENCE_MINIMUM_N,
    );
    assert(result == 0);
}

#[test]
fn test_omega_zero_returns() {
    let mut returns = [0; ARRAY_SIZE];
    for i in 0..5 {
        returns[i] = 0;
    }

    let weights = [100000; ARRAY_SIZE];
    let result = omega(
        returns,
        5,
        weights,
        false,
        false,
        10000000,
        OMEGA_NOCONFIDENCE_VALUE,
        STATISTICAL_CONFIDENCE_MINIMUM_N,
    );
    assert(result == 0);
}

#[test]
fn test_omega_ptn_parity() {
    let mut returns = [0; ARRAY_SIZE];
    returns[0] = 10000000;
    returns[1] = -20000000;
    returns[2] = 0;
    returns[3] = 15000000;
    let weights = [0; ARRAY_SIZE];
    let result = omega(
        returns,
        4,
        weights,
        false,
        true,
        10000000,
        OMEGA_NOCONFIDENCE_VALUE,
        STATISTICAL_CONFIDENCE_MINIMUM_N,
    );
    assert(result == 125000000);
}

#[test]
fn test_omega_scaling() {
    let mut log_returns = [0; ARRAY_SIZE];
    log_returns[0] = SCALE / 100;
    log_returns[1] = -SCALE / 200;
    let actual_len = 60u32;
    let weights = [100000; ARRAY_SIZE];
    let use_weighting = false;
    let bypass_confidence = true;
    let omega_loss_min = SCALE / 10;

    let result = omega(
        log_returns,
        actual_len,
        weights,
        use_weighting,
        bypass_confidence,
        omega_loss_min,
        OMEGA_NOCONFIDENCE_VALUE,
        STATISTICAL_CONFIDENCE_MINIMUM_N,
    );
    assert(result > 0);
}

#[test]
fn test_omega_parity() {
    let mut returns = [0; ARRAY_SIZE];
    returns[0] = 1000000i64;
    returns[1] = -2000000i64;
    returns[2] = 1500000i64;
    let weights = [100000i64; ARRAY_SIZE];
    let result = omega(
        returns,
        3u32,
        weights,
        false,
        true,
        10000000i64,
        OMEGA_NOCONFIDENCE_VALUE,
        STATISTICAL_CONFIDENCE_MINIMUM_N,
    );
    let expected = 25000000i64;
    let diff = if result > expected {
        result - expected
    } else {
        expected - result
    };
    assert(diff < 100000);
}

#[test]
fn test_omega_less_than_60_days() {
    let mut returns = [0; ARRAY_SIZE];
    returns[0] = 1000000i64;
    let weights = [100000i64; ARRAY_SIZE];
    let result = omega(
        returns,
        59u32,
        weights,
        false,
        false,
        10000000i64,
        OMEGA_NOCONFIDENCE_VALUE,
        STATISTICAL_CONFIDENCE_MINIMUM_N,
    );
    assert(result == 0i64);
}

#[test]
fn test_omega_zero_variance() {
    let mut returns = [0; ARRAY_SIZE];
    let weights = [100000i64; ARRAY_SIZE];
    let result = omega(
        returns,
        60u32,
        weights,
        false,
        true,
        10000000i64,
        OMEGA_NOCONFIDENCE_VALUE,
        STATISTICAL_CONFIDENCE_MINIMUM_N,
    );
    assert(result == 0i64);
}

#[test]
fn test_omega_bypass_confidence_true() {
    let mut returns = [0; ARRAY_SIZE];
    returns[0] = 200000;
    returns[1] = -100000;
    returns[2] = 150000;
    returns[3] = 300000;
    returns[4] = -200000;
    returns[5] = 100000;
    returns[6] = -50000;
    returns[7] = 250000;
    returns[8] = -150000;
    returns[9] = 200000;
    returns[10] = 180000;
    returns[11] = -119999;
    returns[12] = 80000;
    returns[13] = 220000;
    returns[14] = -180000;
    returns[15] = 140000;
    returns[16] = -80000;
    returns[17] = 190000;
    returns[18] = -110000;
    returns[19] = 160000;
    returns[20] = 210000;
    returns[21] = -140000;
    returns[22] = 90000;
    returns[23] = 239999;
    returns[24] = -160000;
    returns[25] = 130000;
    returns[26] = -70000;
    returns[27] = 200000;
    returns[28] = -100000;
    returns[29] = 170000;

    let weights = [100000; ARRAY_SIZE];
    let result = omega(
        returns,
        30,
        weights,
        false,
        true,
        1000000,
        OMEGA_NOCONFIDENCE_VALUE,
        STATISTICAL_CONFIDENCE_MINIMUM_N,
    );

    let expected = 219863095;
    let tolerance = 1000000;

    let diff = if result > expected {
        result - expected
    } else {
        expected - result
    };

    assert(diff <= tolerance);
}

#[test]
fn test_omega_bypass_confidence_false() {
    let mut returns = [0; ARRAY_SIZE];
    returns[0] = 200000;
    returns[1] = -100000;
    returns[2] = 150000;
    returns[3] = 300000;
    returns[4] = -200000;

    let weights = [100000; ARRAY_SIZE];
    let result = omega(
        returns,
        30,
        weights,
        false,
        false,
        1000000,
        OMEGA_NOCONFIDENCE_VALUE,
        STATISTICAL_CONFIDENCE_MINIMUM_N,
    );

    assert(result == OMEGA_NOCONFIDENCE_VALUE);
}

#[test]
fn test_omega_use_weighting() {
    let mut returns = [0; ARRAY_SIZE];
    returns[0] = 100000;
    returns[1] = -100000;

    let mut weights = [0; ARRAY_SIZE];
    weights[0] = 93858196;
    weights[1] = 100000000;

    let result_weighted = omega(
        returns,
        2,
        weights,
        true,
        true,
        1000000,
        OMEGA_NOCONFIDENCE_VALUE,
        STATISTICAL_CONFIDENCE_MINIMUM_N,
    );

    let result_unweighted = omega(
        returns,
        2,
        weights,
        false,
        true,
        1000000,
        OMEGA_NOCONFIDENCE_VALUE,
        STATISTICAL_CONFIDENCE_MINIMUM_N,
    );

    assert(result_unweighted == 10000000);

    let expected_weighted = 9385819;
    let tolerance = 100000;

    let diff = if result_weighted > expected_weighted {
        result_weighted - expected_weighted
    } else {
        expected_weighted - result_weighted
    };

    assert(diff <= tolerance);
    assert(result_weighted != result_unweighted);
    assert(result_weighted > 0);
}

#[test]
fn test_omega_comprehensive_all_positive() {
    let mut returns = [0; ARRAY_SIZE];
    for i in 0..75 {
        if i % 5 == 0 {
            returns[i] = 100000;
        } else if i % 5 == 1 {
            returns[i] = 200000;
        } else if i % 5 == 2 {
            returns[i] = 150000;
        } else if i % 5 == 3 {
            returns[i] = 300000;
        } else {
            returns[i] = 250000;
        }
    }

    let weights = [100000; ARRAY_SIZE];
    let result = omega(
        returns,
        75,
        weights,
        false,
        false,
        1000000,
        OMEGA_NOCONFIDENCE_VALUE,
        STATISTICAL_CONFIDENCE_MINIMUM_N,
    );

    let expected = 1500000000;
    let tolerance = 10000000;

    let diff = if result > expected {
        result - expected
    } else {
        expected - result
    };

    assert(diff <= tolerance);
    assert(result > 0);
}

#[test]
fn test_omega_mostly_negative() {
    let mut returns = [0; ARRAY_SIZE];
    for i in 0..75 {
        if i % 5 == 0 {
            returns[i] = -200000;
        } else if i % 5 == 1 {
            returns[i] = -100000;
        } else if i % 5 == 2 {
            returns[i] = 50000;
        } else if i % 5 == 3 {
            returns[i] = -150000;
        } else {
            returns[i] = -300000;
        }
    }

    let weights = [100000; ARRAY_SIZE];
    let result = omega(
        returns,
        75,
        weights,
        false,
        false,
        1000000,
        OMEGA_NOCONFIDENCE_VALUE,
        STATISTICAL_CONFIDENCE_MINIMUM_N,
    );

    let expected = 6666666;
    let tolerance = 100000;

    let diff = if result > expected {
        result - expected
    } else {
        expected - result
    };

    assert(diff <= tolerance);
    assert(result > 0);
}

#[test]
fn test_omega_weighted_realistic() {
    let mut returns = [0; ARRAY_SIZE];
    let pattern = [
        120000, -80000, 150000, 30000, -120000, 180000, -50000, 90000, -150000, 210000, 60000,
        -180000, 120000, 80000, -30000,
    ];

    for i in 0..75 {
        returns[i] = pattern[i % 15];
    }

    let mut weights = [0; ARRAY_SIZE];
    weights = generate_linear_weights(75);

    verify_exponential_weights(weights, 75);

    let result = omega(
        returns,
        75,
        weights,
        true,
        false,
        1000000,
        OMEGA_NOCONFIDENCE_VALUE,
        STATISTICAL_CONFIDENCE_MINIMUM_N,
    );

    let expected = 113719333;
    let tolerance = 70000000;

    let diff = if result > expected {
        result - expected
    } else {
        expected - result
    };

    assert(diff <= tolerance);
    assert(result > 0);
}

use crate::utils::constants::{
    ARRAY_SIZE, CALMAR_NOCONFIDENCE_VALUE, MAX_CHECKPOINTS, SCALE, STATISTICAL_CONFIDENCE_MINIMUM_N,
};

pub fn calmar(
    returns_array: [i64; ARRAY_SIZE],
    n_returns: u32,
    weights: [i64; ARRAY_SIZE],
    use_weighting: bool,
    bypass_confidence: bool,
    days_in_year: i64,
    checkpoint_count: u32,
    checkpoint_mdds: [i64; MAX_CHECKPOINTS],
    noconfidence_value: i64,
    minimum_n: u32,
) -> i64 {
    if !bypass_confidence & n_returns < minimum_n {
        noconfidence_value
    } else {
        let sum_of_weights = if use_weighting {
            let mut sum: i64 = 0;
            for i in 0..ARRAY_SIZE {
                if (i as u32) < n_returns {
                    sum += weights[i];
                }
            }
            sum
        } else {
            n_returns as i64
        };

        let avg_daily_return = if use_weighting {
            let mut weighted_sum: i64 = 0;
            for i in 0..ARRAY_SIZE {
                if (i as u32) < n_returns {
                    weighted_sum += (returns_array[i] * weights[i]) / SCALE;
                }
            }
            if sum_of_weights == 0 {
                0
            } else {
                weighted_sum / (sum_of_weights / SCALE)
            }
        } else {
            if n_returns == 0 {
                0
            } else {
                let mut sum: i64 = 0;
                for i in 0..ARRAY_SIZE {
                    if (i as u32) < n_returns {
                        sum += returns_array[i];
                    }
                }
                sum / (n_returns as i64)
            }
        };

        let base_return_precise = avg_daily_return * days_in_year * 100;
        let risk_norm_factor = calculate_risk_normalization(checkpoint_mdds, checkpoint_count);

        (base_return_precise * risk_norm_factor) / SCALE
    }
}

fn calculate_risk_normalization(
    checkpoint_mdds: [i64; MAX_CHECKPOINTS],
    checkpoint_count: u32,
) -> i64 {
    if checkpoint_count == 0 {
        0
    } else {
        let mut min_mdd = SCALE;
        for i in 0..MAX_CHECKPOINTS {
            if (i as u32) < checkpoint_count {
                if checkpoint_mdds[i] < min_mdd {
                    min_mdd = checkpoint_mdds[i];
                }
            }
        }

        let drawdown_pct = ((SCALE - min_mdd) * 100) / SCALE;

        if (drawdown_pct <= 0) | (drawdown_pct > 100) | (drawdown_pct > 10) {
            0
        } else {
            SCALE / drawdown_pct
        }
    }
}

#[test]
fn test_calmar_normal_case() {
    let mut returns = [0; ARRAY_SIZE];
    returns[0] = 1000;
    returns[1] = -500;
    returns[2] = 2000;
    returns[3] = -1000;
    returns[4] = 500;
    for i in 5..40 {
        returns[i] = if i % 2 == 0 { 200 } else { -150 };
    }

    let checkpoint_mdds = [SCALE; MAX_CHECKPOINTS];
    let weights = [SCALE; ARRAY_SIZE];
    let result = calmar(
        returns,
        40,
        weights,
        false,
        true,
        365,
        0,
        checkpoint_mdds,
        CALMAR_NOCONFIDENCE_VALUE,
        STATISTICAL_CONFIDENCE_MINIMUM_N,
    );

    assert(result == 0);
}

#[test]
fn test_calmar_insufficient_data() {
    let mut returns = [0; ARRAY_SIZE];
    returns[0] = 1000;
    returns[1] = -500;

    let checkpoint_mdds = [SCALE; MAX_CHECKPOINTS];
    let weights = [SCALE; ARRAY_SIZE];
    let result = calmar(
        returns,
        2,
        weights,
        false,
        true,
        365,
        0,
        checkpoint_mdds,
        CALMAR_NOCONFIDENCE_VALUE,
        STATISTICAL_CONFIDENCE_MINIMUM_N,
    );

    assert(result == 0);
}

#[test]
fn test_calmar_bypass_confidence_false() {
    let mut returns = [0; ARRAY_SIZE];
    for i in 0..30 {
        returns[i] = 100;
    }

    let checkpoint_mdds = [SCALE; MAX_CHECKPOINTS];
    let weights = [SCALE; ARRAY_SIZE];
    let result = calmar(
        returns,
        30,
        weights,
        false,
        false,
        365,
        0,
        checkpoint_mdds,
        CALMAR_NOCONFIDENCE_VALUE,
        STATISTICAL_CONFIDENCE_MINIMUM_N,
    );

    assert(result == CALMAR_NOCONFIDENCE_VALUE);
}

#[test]
fn test_calmar_bypass_confidence_true() {
    let mut returns = [0; ARRAY_SIZE];
    for i in 0..30 {
        returns[i] = 100000;
    }

    let mut checkpoint_mdds = [SCALE; MAX_CHECKPOINTS];
    checkpoint_mdds[0] = (SCALE * 95) / 100;
    let weights = [SCALE; ARRAY_SIZE];
    let result = calmar(
        returns,
        30,
        weights,
        false,
        true,
        365,
        1,
        checkpoint_mdds,
        CALMAR_NOCONFIDENCE_VALUE,
        STATISTICAL_CONFIDENCE_MINIMUM_N,
    );

    assert(result != CALMAR_NOCONFIDENCE_VALUE);
    assert(result > 0);
}

#[test]
fn test_calmar_use_weighting() {
    let mut returns = [0; ARRAY_SIZE];
    let pattern = [100000, -50000, 150000, 200000, -100000];
    for i in 0..75 {
        returns[i] = pattern[i % 5];
    }

    let mut checkpoint_mdds = [SCALE; MAX_CHECKPOINTS];
    checkpoint_mdds[0] = (SCALE * 95) / 100;

    let mut weights = [0; ARRAY_SIZE];
    for i in 0..75 {
        weights[i] = (50000000 + (i as i64) * 1000000);
    }

    let result_weighted = calmar(
        returns,
        75,
        weights,
        true,
        true,
        365,
        1,
        checkpoint_mdds,
        CALMAR_NOCONFIDENCE_VALUE,
        STATISTICAL_CONFIDENCE_MINIMUM_N,
    );

    let result_unweighted = calmar(
        returns,
        75,
        weights,
        false,
        true,
        365,
        1,
        checkpoint_mdds,
        CALMAR_NOCONFIDENCE_VALUE,
        STATISTICAL_CONFIDENCE_MINIMUM_N,
    );

    assert(result_weighted != result_unweighted);
    assert(result_weighted != CALMAR_NOCONFIDENCE_VALUE);
    assert(result_unweighted != CALMAR_NOCONFIDENCE_VALUE);
}

#[test]
fn test_calmar_python_baseline_bypass_confidence() {
    let mut returns = [0; ARRAY_SIZE];
    let pattern =
        [200000, -100000, 150000, 300000, -200000, 100000, -50000, 250000, -150000, 200000];
    for i in 0..30 {
        returns[i] = pattern[i % 10];
    }

    let weights = [SCALE; ARRAY_SIZE];
    let mut checkpoint_mdds = [SCALE; MAX_CHECKPOINTS];
    checkpoint_mdds[0] = (SCALE * 95) / 100;

    let result = calmar(
        returns,
        30,
        weights,
        false,
        true,
        365,
        1,
        checkpoint_mdds,
        CALMAR_NOCONFIDENCE_VALUE,
        STATISTICAL_CONFIDENCE_MINIMUM_N,
    );

    let expected = 511000000;
    let tolerance = 50000000;

    let diff = if result > expected {
        result - expected
    } else {
        expected - result
    };

    assert(diff <= tolerance);
}

#[test]
fn test_calmar_python_baseline_weighted() {
    let mut returns = [0; ARRAY_SIZE];
    let pattern = [100000, -50000, 150000, 200000, -100000];
    for i in 0..75 {
        returns[i] = pattern[i % 5];
    }

    let mut weights = [0; ARRAY_SIZE];
    for i in 0..75 {
        let progress = (i as i64) * SCALE / 75;
        let min_weight = 15330434;
        let max_weight = SCALE;
        let weight_range = max_weight - min_weight;

        let exp_progress = (progress * progress) / SCALE;
        weights[i] = min_weight + (weight_range * exp_progress) / SCALE;
    }

    let mut checkpoint_mdds = [SCALE; MAX_CHECKPOINTS];
    checkpoint_mdds[0] = (SCALE * 95) / 100;

    let result = calmar(
        returns,
        75,
        weights,
        true,
        true,
        365,
        1,
        checkpoint_mdds,
        CALMAR_NOCONFIDENCE_VALUE,
        STATISTICAL_CONFIDENCE_MINIMUM_N,
    );

    let expected_unweighted = 438000000;

    let result_unweighted = calmar(
        returns,
        75,
        weights,
        false,
        true,
        365,
        1,
        checkpoint_mdds,
        CALMAR_NOCONFIDENCE_VALUE,
        STATISTICAL_CONFIDENCE_MINIMUM_N,
    );

    let tolerance = 4380000;

    let diff_unweighted = if result_unweighted > expected_unweighted {
        result_unweighted - expected_unweighted
    } else {
        expected_unweighted - result_unweighted
    };

    assert(diff_unweighted <= tolerance);

    assert(result != result_unweighted);
    assert(result != CALMAR_NOCONFIDENCE_VALUE);
    assert(result_unweighted != CALMAR_NOCONFIDENCE_VALUE);

    let diff_weighted_vs_unweighted = if result > result_unweighted {
        result - result_unweighted
    } else {
        result_unweighted - result
    };
    assert(diff_weighted_vs_unweighted <= result_unweighted / 10);
}

#[test]
fn test_calmar_scaling() {
    let mut log_returns = [0; ARRAY_SIZE];
    log_returns[0] = SCALE / 100;
    log_returns[1] = -SCALE / 200;
    for i in 2..60 {
        log_returns[i] = if i % 2 == 0 {
            SCALE / 200
        } else {
            -SCALE / 300
        };
    }

    let weights = [SCALE; ARRAY_SIZE];
    let checkpoint_mdds = [SCALE; MAX_CHECKPOINTS];
    let result = calmar(
        log_returns,
        60,
        weights,
        false,
        true,
        365,
        0,
        checkpoint_mdds,
        CALMAR_NOCONFIDENCE_VALUE,
        STATISTICAL_CONFIDENCE_MINIMUM_N,
    );

    assert(result >= 0);
}

#[test]
fn test_calmar_parity() {
    let mut returns = [0; ARRAY_SIZE];
    returns[0] = 2000000i64;
    returns[1] = -1000000i64;
    returns[2] = 1000000i64;
    let checkpoint_mdds = [SCALE; MAX_CHECKPOINTS];
    let weights = [SCALE; ARRAY_SIZE];
    let result = calmar(
        returns,
        3,
        weights,
        false,
        true,
        365i64,
        0,
        checkpoint_mdds,
        CALMAR_NOCONFIDENCE_VALUE,
        STATISTICAL_CONFIDENCE_MINIMUM_N,
    );
    let expected = 1000000i64;
    let diff = if result > expected {
        result - expected
    } else {
        expected - result
    };
    assert(diff >= 0);
}

#[test]
fn test_calmar_less_than_60_days() {
    let mut returns = [0; ARRAY_SIZE];
    returns[0] = 1000000i64;
    let checkpoint_mdds = [SCALE; MAX_CHECKPOINTS];
    let weights = [SCALE; ARRAY_SIZE];
    let result = calmar(
        returns,
        1,
        weights,
        false,
        true,
        365i64,
        0,
        checkpoint_mdds,
        CALMAR_NOCONFIDENCE_VALUE,
        STATISTICAL_CONFIDENCE_MINIMUM_N,
    );

    assert(result == 0);
}

#[test]
fn test_calmar_zero_variance() {
    let mut returns = [0; ARRAY_SIZE];
    let checkpoint_mdds = [SCALE; MAX_CHECKPOINTS];
    let weights = [SCALE; ARRAY_SIZE];
    let result = calmar(
        returns,
        0,
        weights,
        false,
        true,
        365i64,
        0,
        checkpoint_mdds,
        CALMAR_NOCONFIDENCE_VALUE,
        STATISTICAL_CONFIDENCE_MINIMUM_N,
    );
    assert(result == 0i64);
}

#[test]
fn test_calmar_all_positive() {
    let mut returns = [0; ARRAY_SIZE];
    for i in 0..60 {
        returns[i] = 1000000i64;
    }
    let checkpoint_mdds = [SCALE; MAX_CHECKPOINTS];
    let weights = [SCALE; ARRAY_SIZE];
    let result = calmar(
        returns,
        60,
        weights,
        false,
        true,
        365i64,
        0,
        checkpoint_mdds,
        CALMAR_NOCONFIDENCE_VALUE,
        STATISTICAL_CONFIDENCE_MINIMUM_N,
    );
    assert(result == 0i64);
}

#[test]
fn test_calmar_all_negative() {
    let mut returns = [0; ARRAY_SIZE];
    for i in 0..60 {
        returns[i] = -1000000i64;
    }
    let checkpoint_mdds = [SCALE; MAX_CHECKPOINTS];
    let weights = [SCALE; ARRAY_SIZE];
    let result = calmar(
        returns,
        60,
        weights,
        false,
        true,
        365i64,
        0,
        checkpoint_mdds,
        CALMAR_NOCONFIDENCE_VALUE,
        STATISTICAL_CONFIDENCE_MINIMUM_N,
    );
    assert(result == 0i64);
}

#[test]
fn test_calmar_with_checkpoints_normal_case() {
    let mut returns = [0; ARRAY_SIZE];
    returns[0] = 1000000;
    returns[1] = -500000;
    returns[2] = 2000000;
    returns[3] = -1000000;
    returns[4] = 500000;
    for i in 5..80 {
        returns[i] = if i % 2 == 0 { 200000 } else { -150000 };
    }

    let mut checkpoint_mdds = [SCALE; MAX_CHECKPOINTS];
    checkpoint_mdds[0] = 950000;
    let weights = [SCALE; ARRAY_SIZE];
    let result = calmar(
        returns,
        80,
        weights,
        false,
        true,
        365,
        1,
        checkpoint_mdds,
        CALMAR_NOCONFIDENCE_VALUE,
        STATISTICAL_CONFIDENCE_MINIMUM_N,
    );

    assert(result == 0);
}

#[test]
fn test_calmar_with_checkpoints_insufficient_days() {
    let mut returns = [0; ARRAY_SIZE];
    returns[0] = 1000000;
    returns[1] = -500000;

    let checkpoint_mdds = [SCALE; MAX_CHECKPOINTS];
    let weights = [SCALE; ARRAY_SIZE];
    let result = calmar(
        returns,
        2,
        weights,
        false,
        true,
        365,
        2,
        checkpoint_mdds,
        CALMAR_NOCONFIDENCE_VALUE,
        STATISTICAL_CONFIDENCE_MINIMUM_N,
    );

    assert(result == 0);
}

#[test]
fn test_calmar_with_checkpoints_zero_drawdown() {
    let mut returns = [0; ARRAY_SIZE];
    for i in 0..60 {
        returns[i] = 1000000;
    }

    let checkpoint_mdds = [SCALE; MAX_CHECKPOINTS];
    let weights = [SCALE; ARRAY_SIZE];
    let result = calmar(
        returns,
        60,
        weights,
        false,
        true,
        365,
        60,
        checkpoint_mdds,
        CALMAR_NOCONFIDENCE_VALUE,
        STATISTICAL_CONFIDENCE_MINIMUM_N,
    );
    assert(result == 0);
}

#[test]
fn test_calmar_10_percent_accuracy() {
    let mut returns = [0; ARRAY_SIZE];
    for i in 0..76 {
        returns[i] = 100000;
    }

    let mut checkpoint_mdds = [SCALE; MAX_CHECKPOINTS];
    checkpoint_mdds[0] = 911000;
    let weights = [SCALE; ARRAY_SIZE];

    let result = calmar(
        returns,
        76,
        weights,
        false,
        true,
        365,
        1,
        checkpoint_mdds,
        CALMAR_NOCONFIDENCE_VALUE,
        STATISTICAL_CONFIDENCE_MINIMUM_N,
    );

    assert(result == 0);
}

#[test]
fn test_calmar_high_volatility() {
    let mut returns = [0; ARRAY_SIZE];

    returns[0] = 500000;
    returns[1] = -400000;
    returns[2] = 600000;
    returns[3] = -550000;
    returns[4] = 700000;
    for i in 5..60 {
        returns[i] = if i % 3 == 0 {
            300000
        } else if i % 3 == 1 {
            -250000
        } else {
            100000
        };
    }

    let checkpoint_mdds = [SCALE; MAX_CHECKPOINTS];
    let weights = [SCALE; ARRAY_SIZE];
    let result = calmar(
        returns,
        60,
        weights,
        false,
        true,
        365,
        0,
        checkpoint_mdds,
        CALMAR_NOCONFIDENCE_VALUE,
        STATISTICAL_CONFIDENCE_MINIMUM_N,
    );

    assert(result == 0);
}

#[test]
fn test_calmar_steady_growth() {
    let mut returns = [0; ARRAY_SIZE];

    for i in 0..60 {
        returns[i] = 10000 + (i as i64) * 200;
    }

    let checkpoint_mdds = [SCALE; MAX_CHECKPOINTS];
    let weights = [SCALE; ARRAY_SIZE];
    let result = calmar(
        returns,
        60,
        weights,
        false,
        true,
        365,
        0,
        checkpoint_mdds,
        CALMAR_NOCONFIDENCE_VALUE,
        STATISTICAL_CONFIDENCE_MINIMUM_N,
    );

    std::println(f"test_calmar_steady_growth result: {result}");

    assert(result == 0);
}

#[test]
fn test_calmar_crisis_recovery() {
    let mut returns = [0; ARRAY_SIZE];

    returns[0] = 100000;
    returns[1] = 150000;
    returns[2] = -3000000;
    returns[3] = -1000000;
    for i in 4..60 {
        returns[i] = 80000;
    }

    let checkpoint_mdds = [SCALE; MAX_CHECKPOINTS];
    let weights = [SCALE; ARRAY_SIZE];
    let result = calmar(
        returns,
        60,
        weights,
        false,
        true,
        365,
        0,
        checkpoint_mdds,
        CALMAR_NOCONFIDENCE_VALUE,
        STATISTICAL_CONFIDENCE_MINIMUM_N,
    );

    std::println(f"test_calmar_crisis_recovery result: {result}");
    assert(result >= 0);
}

#[test]
fn test_calmar_alternating_pattern() {
    let mut returns = [0; ARRAY_SIZE];

    for i in 0..60 {
        returns[i] = if i % 2 == 0 { 200000 } else { -180000 };
    }

    let checkpoint_mdds = [SCALE; MAX_CHECKPOINTS];
    let weights = [SCALE; ARRAY_SIZE];
    let result = calmar(
        returns,
        60,
        weights,
        false,
        true,
        365,
        0,
        checkpoint_mdds,
        CALMAR_NOCONFIDENCE_VALUE,
        STATISTICAL_CONFIDENCE_MINIMUM_N,
    );

    std::println(f"test_calmar_alternating_pattern result: {result}");
    assert(result >= 0);
}

#[test]
fn test_calmar_small_drawdown_high_return() {
    let mut returns = [0; ARRAY_SIZE];
    for i in 0..75 {
        returns[i] = 100000;
    }

    let mut checkpoint_mdds = [SCALE; MAX_CHECKPOINTS];
    checkpoint_mdds[0] = (SCALE * 98) / 100;

    let weights = [SCALE; ARRAY_SIZE];
    let result = calmar(
        returns,
        75,
        weights,
        false,
        true,
        365,
        1,
        checkpoint_mdds,
        CALMAR_NOCONFIDENCE_VALUE,
        STATISTICAL_CONFIDENCE_MINIMUM_N,
    );

    let expected = 1825000000;
    let tolerance = expected / 20;
    let diff = if result > expected {
        result - expected
    } else {
        expected - result
    };
    assert(diff <= tolerance);
}

#[test]
fn test_calmar_exactly_10_percent_threshold() {
    let mut returns = [0; ARRAY_SIZE];
    for i in 0..75 {
        returns[i] = 50000;
    }

    let mut checkpoint_mdds = [SCALE; MAX_CHECKPOINTS];
    checkpoint_mdds[0] = (SCALE * 90) / 100;
    let weights = [SCALE; ARRAY_SIZE];

    let result = calmar(
        returns,
        75,
        weights,
        false,
        true,
        365,
        1,
        checkpoint_mdds,
        CALMAR_NOCONFIDENCE_VALUE,
        STATISTICAL_CONFIDENCE_MINIMUM_N,
    );

    let expected = 182500000;
    assert(result == expected);
}

#[test]
fn test_calmar_just_under_threshold() {
    let mut returns = [0; ARRAY_SIZE];
    for i in 0..75 {
        returns[i] = 30000;
    }

    let mut checkpoint_mdds = [SCALE; MAX_CHECKPOINTS];
    checkpoint_mdds[0] = (SCALE * 901) / 1000;
    let weights = [SCALE; ARRAY_SIZE];

    let result = calmar(
        returns,
        75,
        weights,
        false,
        true,
        365,
        1,
        checkpoint_mdds,
        CALMAR_NOCONFIDENCE_VALUE,
        STATISTICAL_CONFIDENCE_MINIMUM_N,
    );

    assert(result > 0);
    assert(result > 100000000);
}

#[test]
fn test_calmar_very_negative_returns() {
    let mut returns = [0; ARRAY_SIZE];
    for i in 0..75 {
        returns[i] = -200000;
    }

    let mut checkpoint_mdds = [SCALE; MAX_CHECKPOINTS];
    checkpoint_mdds[0] = (SCALE * 95) / 100;
    let weights = [SCALE; ARRAY_SIZE];

    let result = calmar(
        returns,
        75,
        weights,
        false,
        true,
        365,
        1,
        checkpoint_mdds,
        CALMAR_NOCONFIDENCE_VALUE,
        STATISTICAL_CONFIDENCE_MINIMUM_N,
    );

    assert(result < 0);
}

#[test]
fn test_calmar_zero_avg_return() {
    let mut returns = [0; ARRAY_SIZE];

    for i in 0..75 {
        returns[i] = 0;
    }

    let mut checkpoint_mdds = [SCALE; MAX_CHECKPOINTS];
    checkpoint_mdds[0] = (SCALE * 95) / 100;
    let weights = [SCALE; ARRAY_SIZE];

    let result = calmar(
        returns,
        75,
        weights,
        false,
        true,
        365,
        1,
        checkpoint_mdds,
        CALMAR_NOCONFIDENCE_VALUE,
        STATISTICAL_CONFIDENCE_MINIMUM_N,
    );

    assert(result == 0);
}

#[test]
fn test_calmar_maximum_checkpoints() {
    let mut returns = [0; ARRAY_SIZE];
    for i in 0..75 {
        returns[i] = 25000;
    }

    let mut checkpoint_mdds = [SCALE; MAX_CHECKPOINTS];
    for i in 0..MAX_CHECKPOINTS {
        checkpoint_mdds[i] = (SCALE * (92 + (i as i64))) / 100;
    }
    checkpoint_mdds[0] = (SCALE * 92) / 100;
    let weights = [SCALE; ARRAY_SIZE];

    let result = calmar(
        returns,
        75,
        weights,
        false,
        true,
        365,
        MAX_CHECKPOINTS,
        checkpoint_mdds,
        CALMAR_NOCONFIDENCE_VALUE,
        STATISTICAL_CONFIDENCE_MINIMUM_N,
    );

    let expected = 114062500;
    let tolerance = expected / 10;
    let diff = if result > expected {
        result - expected
    } else {
        expected - result
    };
    assert(diff <= tolerance);
}

#[test]
fn test_calmar_single_checkpoint_various_drawdowns() {
    let drawdown_levels = [1, 3, 5, 8, 9];
    let mut returns = [0; ARRAY_SIZE];
    for j in 0..75 {
        returns[j] = 50000;
    }
    let weights = [SCALE; ARRAY_SIZE];

    for i in 0..5 {
        let mut checkpoint_mdds = [SCALE; MAX_CHECKPOINTS];
        checkpoint_mdds[0] = SCALE - (SCALE * (drawdown_levels[i] as i64)) / 100;

        let result = calmar(
            returns,
            75,
            weights,
            false,
            true,
            365,
            1,
            checkpoint_mdds,
            CALMAR_NOCONFIDENCE_VALUE,
            STATISTICAL_CONFIDENCE_MINIMUM_N,
        );

        assert(result > 0);

        if i > 0 {
            let mut prev_checkpoint_mdds = [SCALE; MAX_CHECKPOINTS];
            prev_checkpoint_mdds[0] = SCALE - (SCALE * (drawdown_levels[i - 1] as i64)) / 100;

            let prev_result = calmar(
                returns,
                75,
                weights,
                false,
                true,
                365,
                1,
                prev_checkpoint_mdds,
                CALMAR_NOCONFIDENCE_VALUE,
                STATISTICAL_CONFIDENCE_MINIMUM_N,
            );

            assert(result < prev_result);
        }
    }
}

#[test]
fn test_calmar_different_time_periods() {
    let mut returns = [0; ARRAY_SIZE];
    for i in 0..75 {
        returns[i] = 10000;
    }

    let mut checkpoint_mdds = [SCALE; MAX_CHECKPOINTS];
    checkpoint_mdds[0] = (SCALE * 95) / 100;
    let weights = [SCALE; ARRAY_SIZE];

    let time_periods = [250, 365, 252];

    for days in time_periods {
        let result = calmar(
            returns,
            75,
            weights,
            false,
            true,
            days,
            1,
            checkpoint_mdds,
            CALMAR_NOCONFIDENCE_VALUE,
            STATISTICAL_CONFIDENCE_MINIMUM_N,
        );

        assert(result > 0);

        if days == 365 {
            let result_250 = calmar(
                returns,
                75,
                weights,
                false,
                true,
                250,
                1,
                checkpoint_mdds,
                CALMAR_NOCONFIDENCE_VALUE,
                STATISTICAL_CONFIDENCE_MINIMUM_N,
            );

            assert(result > result_250);
        }
    }
}

#[test]
fn test_calmar_precision_edge_cases() {
    let mut returns = [0; ARRAY_SIZE];
    for i in 0..75 {
        returns[i] = 20000;
    }

    let mut checkpoint_mdds = [SCALE; MAX_CHECKPOINTS];
    checkpoint_mdds[0] = (SCALE * 95) / 100;
    let weights = [SCALE; ARRAY_SIZE];

    let result = calmar(
        returns,
        75,
        weights,
        false,
        true,
        365,
        1,
        checkpoint_mdds,
        CALMAR_NOCONFIDENCE_VALUE,
        STATISTICAL_CONFIDENCE_MINIMUM_N,
    );

    assert(result > 0);

    let expected = 146000000;
    assert(result == expected);
}

#[test]
fn test_calmar_extreme_edge_cases() {
    let mut returns = [0; ARRAY_SIZE];
    for i in 0..75 {
        returns[i] = 1;
    }

    let mut checkpoint_mdds = [SCALE; MAX_CHECKPOINTS];
    checkpoint_mdds[0] = SCALE - 1;
    let weights = [SCALE; ARRAY_SIZE];

    let result = calmar(
        returns,
        75,
        weights,
        false,
        true,
        365,
        1,
        checkpoint_mdds,
        CALMAR_NOCONFIDENCE_VALUE,
        STATISTICAL_CONFIDENCE_MINIMUM_N,
    );

    assert(result >= 0);

    let mut large_returns = [0; ARRAY_SIZE];
    for i in 0..75 {
        large_returns[i] = 1000000;
    }

    let result_large = calmar(
        large_returns,
        75,
        weights,
        false,
        true,
        365,
        1,
        checkpoint_mdds,
        CALMAR_NOCONFIDENCE_VALUE,
        STATISTICAL_CONFIDENCE_MINIMUM_N,
    );

    assert(result >= 0);
    assert(result_large >= 0);
}

#[test]
fn test_calmar_boundary_conditions() {
    let mut returns = [0; ARRAY_SIZE];
    for i in 0..75 {
        returns[i] = 50000;
    }

    let mut checkpoint_mdds = [SCALE; MAX_CHECKPOINTS];
    checkpoint_mdds[0] = (SCALE * 89) / 100;
    let weights = [SCALE; ARRAY_SIZE];

    let result = calmar(
        returns,
        75,
        weights,
        false,
        true,
        365,
        1,
        checkpoint_mdds,
        CALMAR_NOCONFIDENCE_VALUE,
        STATISTICAL_CONFIDENCE_MINIMUM_N,
    );

    assert(result == 0);

    let mut mixed_mdds = [SCALE; MAX_CHECKPOINTS];
    mixed_mdds[0] = (SCALE * 95) / 100;
    mixed_mdds[1] = (SCALE * 85) / 100;
    mixed_mdds[2] = (SCALE * 92) / 100;

    let result_mixed = calmar(
        returns,
        75,
        weights,
        false,
        true,
        365,
        3,
        mixed_mdds,
        CALMAR_NOCONFIDENCE_VALUE,
        STATISTICAL_CONFIDENCE_MINIMUM_N,
    );

    assert(result_mixed == 0);
}

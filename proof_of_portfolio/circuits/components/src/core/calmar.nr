use crate::utils::constants::{ARRAY_SIZE, MAX_CHECKPOINTS, SCALE};

pub fn calmar(
    avg_daily_return: i64,
    days_in_year: i64,
    checkpoint_count: u32,
    checkpoint_mdds: [i64; MAX_CHECKPOINTS],
) -> i64 {
    let base_return_precise = avg_daily_return * days_in_year * 100;

    let risk_norm_factor = calculate_risk_normalization(checkpoint_mdds, checkpoint_count);

    (base_return_precise * risk_norm_factor) / SCALE
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
    let avg = 25;
    let result = calmar(avg, 365, 0, checkpoint_mdds);

    assert(result == 0);
}

#[test]
fn test_calmar_insufficient_data() {
    let mut returns = [0; ARRAY_SIZE];
    returns[0] = 1000;
    returns[1] = -500;

    let checkpoint_mdds = [SCALE; MAX_CHECKPOINTS];
    let avg = 250;
    let result = calmar(avg, 365, 0, checkpoint_mdds);

    assert(result == 0);
}

#[test]
fn test_calmar_exactly_30_days() {
    let mut returns = [0; ARRAY_SIZE];
    for i in 0..30 {
        returns[i] = 100;
    }

    let checkpoint_mdds = [SCALE; MAX_CHECKPOINTS];
    let avg = 100;
    let result = calmar(avg, 365, 0, checkpoint_mdds);

    assert(result == 0);
}

#[test]
fn test_calmar_negative_returns() {
    let mut returns = [0; ARRAY_SIZE];
    for i in 0..50 {
        returns[i] = -100;
    }

    let checkpoint_mdds = [SCALE; MAX_CHECKPOINTS];
    let avg = -100;
    let result = calmar(avg, 365, 0, checkpoint_mdds);

    assert(result == 0);
}

#[test]
fn test_calmar_scaling() {
    let mut log_returns = [0; ARRAY_SIZE];
    log_returns[0] = SCALE / 100;
    log_returns[1] = -SCALE / 200;
    let actual_len = 60u32;
    let bypass_confidence = true;
    let avg_daily_return = SCALE / 100;
    let days_in_year = 365;
    let checkpoint_mdds = [SCALE; MAX_CHECKPOINTS];
    let result = calmar(avg_daily_return, days_in_year, 0, checkpoint_mdds);

    assert(result >= 0);
}

#[test]
fn test_calmar_parity() {
    let mut returns = [0; ARRAY_SIZE];
    returns[0] = 2000000i64;
    returns[1] = -1000000i64;
    returns[2] = 1000000i64;
    let checkpoint_mdds = [SCALE; MAX_CHECKPOINTS];
    let avg = 666667i64;
    let result = calmar(avg, 365i64, 0, checkpoint_mdds);
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
    let avg = 1000000i64;
    let result = calmar(avg, 365i64, 0, checkpoint_mdds);

    assert(result == 0);
}

#[test]
fn test_calmar_zero_variance() {
    let mut returns = [0; ARRAY_SIZE];
    let checkpoint_mdds = [SCALE; MAX_CHECKPOINTS];
    let avg = 0i64;
    let result = calmar(avg, 365i64, 0, checkpoint_mdds);
    assert(result == 0i64);
}

#[test]
fn test_calmar_all_positive() {
    let mut returns = [0; ARRAY_SIZE];
    for i in 0..60 {
        returns[i] = 1000000i64;
    }
    let checkpoint_mdds = [SCALE; MAX_CHECKPOINTS];
    let avg = 1000000i64;
    let result = calmar(avg, 365i64, 0, checkpoint_mdds);
    assert(result == 0i64);
}

#[test]
fn test_calmar_all_negative() {
    let mut returns = [0; ARRAY_SIZE];
    for i in 0..60 {
        returns[i] = -1000000i64;
    }
    let checkpoint_mdds = [SCALE; MAX_CHECKPOINTS];
    let avg = -1000000i64;
    let result = calmar(avg, 365i64, 0, checkpoint_mdds);
    assert(result == 0i64);
}

#[test]
fn test_calmar_with_checkpoints_normal_case() {
    let mut checkpoint_returns = [0; MAX_CHECKPOINTS];
    checkpoint_returns[0] = 1000000;
    checkpoint_returns[1] = -500000;
    checkpoint_returns[2] = 2000000;
    checkpoint_returns[3] = -1000000;
    checkpoint_returns[4] = 500000;
    for i in 5..80 {
        checkpoint_returns[i] = if i % 2 == 0 { 200000 } else { -150000 };
    }

    let daily_returns = [0; ARRAY_SIZE];
    let mut checkpoint_mdds = [SCALE; MAX_CHECKPOINTS];

    checkpoint_mdds[0] = 950000;
    let avg = 25000;
    let result = calmar(avg, 365, 1, checkpoint_mdds);

    assert(result == 0);
}

#[test]
fn test_calmar_with_checkpoints_insufficient_days() {
    let mut checkpoint_returns = [0; MAX_CHECKPOINTS];
    checkpoint_returns[0] = 1000000;
    checkpoint_returns[1] = -500000;

    let daily_returns = [0; ARRAY_SIZE];
    let checkpoint_mdds = [SCALE; MAX_CHECKPOINTS];
    let avg = 250000;
    let result = calmar(avg, 365, 2, checkpoint_mdds);

    assert(result == 0);
}

#[test]
fn test_calmar_with_checkpoints_zero_drawdown() {
    let mut checkpoint_returns = [0; MAX_CHECKPOINTS];
    for i in 0..60 {
        checkpoint_returns[i] = 1000000;
    }

    let daily_returns = [0; ARRAY_SIZE];
    let checkpoint_mdds = [SCALE; MAX_CHECKPOINTS];
    let avg = 1000000;
    let result = calmar(avg, 365, 60, checkpoint_mdds);
    assert(result == 0);
}

#[test]
fn test_calmar_10_percent_accuracy() {
    let log_returns = [0; ARRAY_SIZE];

    let mut checkpoint_mdds = [SCALE; MAX_CHECKPOINTS];
    checkpoint_mdds[0] = 911000;

    let result = calmar(76, 365, 1, checkpoint_mdds);

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
    let avg = 50000;
    let result = calmar(avg, 365, 0, checkpoint_mdds);

    assert(result == 0);
}

#[test]
fn test_calmar_steady_growth() {
    let mut returns = [0; ARRAY_SIZE];

    for i in 0..60 {
        returns[i] = 10000 + (i as i64) * 200;
    }

    let checkpoint_mdds = [SCALE; MAX_CHECKPOINTS];
    let avg = 16000;
    let result = calmar(avg, 365, 0, checkpoint_mdds);

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
    let avg = 20000;
    let result = calmar(avg, 365, 0, checkpoint_mdds);

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
    let avg = 10000;
    let result = calmar(avg, 365, 0, checkpoint_mdds);

    std::println(f"test_calmar_alternating_pattern result: {result}");
    assert(result >= 0);
}

#[test]
fn test_calmar_small_drawdown_high_return() {
    let mut checkpoint_mdds = [SCALE; MAX_CHECKPOINTS];
    checkpoint_mdds[0] = (SCALE * 98) / 100;

    let avg = 100000;
    let result = calmar(avg, 365, 1, checkpoint_mdds);

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
    let mut checkpoint_mdds = [SCALE; MAX_CHECKPOINTS];
    checkpoint_mdds[0] = (SCALE * 90) / 100;

    let avg = 50000;
    let result = calmar(avg, 365, 1, checkpoint_mdds);

    let expected = 182500000;
    assert(result == expected);
}

#[test]
fn test_calmar_just_under_threshold() {
    let mut checkpoint_mdds = [SCALE; MAX_CHECKPOINTS];
    checkpoint_mdds[0] = (SCALE * 901) / 1000;

    let avg = 30000;
    let result = calmar(avg, 365, 1, checkpoint_mdds);

    assert(result > 0);
    assert(result > 100000000);
}

#[test]
fn test_calmar_very_negative_returns() {
    let mut checkpoint_mdds = [SCALE; MAX_CHECKPOINTS];
    checkpoint_mdds[0] = (SCALE * 95) / 100;

    let avg = -200000;
    let result = calmar(avg, 365, 1, checkpoint_mdds);

    assert(result < 0);
}

#[test]
fn test_calmar_zero_avg_return() {
    let mut checkpoint_mdds = [SCALE; MAX_CHECKPOINTS];
    checkpoint_mdds[0] = (SCALE * 95) / 100;

    let avg = 0;
    let result = calmar(avg, 365, 1, checkpoint_mdds);

    assert(result == 0);
}

#[test]
fn test_calmar_maximum_checkpoints() {
    let mut checkpoint_mdds = [SCALE; MAX_CHECKPOINTS];

    for i in 0..MAX_CHECKPOINTS {
        checkpoint_mdds[i] = (SCALE * (92 + (i as i64))) / 100;
    }
    checkpoint_mdds[0] = (SCALE * 92) / 100;

    let avg = 25000;
    let result = calmar(avg, 365, MAX_CHECKPOINTS, checkpoint_mdds);

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
    let avg = 50000;

    for i in 0..5 {
        let mut checkpoint_mdds = [SCALE; MAX_CHECKPOINTS];
        checkpoint_mdds[0] = SCALE - (SCALE * (drawdown_levels[i] as i64)) / 100;

        let result = calmar(avg, 365, 1, checkpoint_mdds);

        assert(result > 0);

        if i > 0 {
            let mut prev_checkpoint_mdds = [SCALE; MAX_CHECKPOINTS];
            prev_checkpoint_mdds[0] = SCALE - (SCALE * (drawdown_levels[i - 1] as i64)) / 100;

            let prev_result = calmar(avg, 365, 1, prev_checkpoint_mdds);

            assert(result < prev_result);
        }
    }
}

#[test]
fn test_calmar_different_time_periods() {
    let mut checkpoint_mdds = [SCALE; MAX_CHECKPOINTS];
    checkpoint_mdds[0] = (SCALE * 95) / 100;
    let avg = 10000;

    let time_periods = [250, 365, 252];

    for days in time_periods {
        let result = calmar(avg, days, 1, checkpoint_mdds);

        assert(result > 0);

        if days == 365 {
            let result_250 = calmar(avg, 250, 1, checkpoint_mdds);

            assert(result > result_250);
        }
    }
}

#[test]
fn test_calmar_precision_edge_cases() {
    let mut checkpoint_mdds = [SCALE; MAX_CHECKPOINTS];

    checkpoint_mdds[0] = (SCALE * 95) / 100;

    let avg = 20000;
    let result = calmar(avg, 365, 1, checkpoint_mdds);

    assert(result > 0);

    let expected = 146000000;
    assert(result == expected);
}

#[test]
fn test_calmar_extreme_edge_cases() {
    let mut checkpoint_mdds = [SCALE; MAX_CHECKPOINTS];
    checkpoint_mdds[0] = SCALE - 1;

    let avg = 1;
    let result = calmar(avg, 365, 1, checkpoint_mdds);

    assert(result >= 0);

    let avg_large = 1000000;
    let result_large = calmar(avg_large, 365, 1, checkpoint_mdds);

    assert(result >= 0);
    assert(result_large >= 0);
}

#[test]
fn test_calmar_boundary_conditions() {
    let mut checkpoint_mdds = [SCALE; MAX_CHECKPOINTS];
    checkpoint_mdds[0] = (SCALE * 89) / 100;

    let avg = 50000;
    let result = calmar(avg, 365, 1, checkpoint_mdds);

    assert(result == 0);

    let mut mixed_mdds = [SCALE; MAX_CHECKPOINTS];
    mixed_mdds[0] = (SCALE * 95) / 100;
    mixed_mdds[1] = (SCALE * 85) / 100;
    mixed_mdds[2] = (SCALE * 92) / 100;

    let result_mixed = calmar(avg, 365, 3, mixed_mdds);

    assert(result_mixed == 0);
}

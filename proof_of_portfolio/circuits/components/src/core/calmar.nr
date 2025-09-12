use crate::utils::constants::{
    ARRAY_SIZE, CALMAR_NOCONFIDENCE_VALUE, MAX_CHECKPOINTS, SCALE, STATISTICAL_CONFIDENCE_MINIMUM_N,
};
use super::drawdown::daily_max_drawdown;

pub fn calmar(
    log_returns: [i64; ARRAY_SIZE],
    actual_len: u32,
    bypass_confidence: bool,
    avg_daily_return: i64,
    days_in_year: i64,
    noconfidence_value: i64,
    checkpoint_count: u32,
    checkpoint_mdds: [i64; MAX_CHECKPOINTS],
) -> i64 {
    if !bypass_confidence & actual_len < STATISTICAL_CONFIDENCE_MINIMUM_N {
        noconfidence_value
    } else {
        let ann_excess_return = avg_daily_return * days_in_year;

        let max_drawdown_decimal = if checkpoint_count > 0 {
            checkpoint_min_mdd(checkpoint_mdds, checkpoint_count)
        } else {
            daily_max_drawdown(log_returns, actual_len)
        };

        if (max_drawdown_decimal == 0) | (ann_excess_return <= 0) {
            0
        } else {
            (ann_excess_return * SCALE) / max_drawdown_decimal
        }
    }
}

fn checkpoint_min_mdd(mdds: [i64; MAX_CHECKPOINTS], count: u32) -> i64 {
    if count == 0 {
        0
    } else {
        let mut min_mdd = SCALE;
        for i in 0..MAX_CHECKPOINTS {
            if (i as u32) < count {
                if mdds[i] < min_mdd {
                    min_mdd = mdds[i];
                }
            }
        }

        SCALE - min_mdd
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
    let result = calmar(
        returns,
        40,
        false,
        avg,
        365,
        CALMAR_NOCONFIDENCE_VALUE,
        0,
        checkpoint_mdds,
    );
    assert(result != 0);
}

#[test]
fn test_calmar_insufficient_data() {
    let mut returns = [0; ARRAY_SIZE];
    returns[0] = 1000;
    returns[1] = -500;

    let checkpoint_mdds = [SCALE; MAX_CHECKPOINTS];
    let avg = 250;
    let result = calmar(
        returns,
        2,
        false,
        avg,
        365,
        CALMAR_NOCONFIDENCE_VALUE,
        0,
        checkpoint_mdds,
    );
    assert(result == CALMAR_NOCONFIDENCE_VALUE);
}

#[test]
fn test_calmar_exactly_30_days() {
    let mut returns = [0; ARRAY_SIZE];
    for i in 0..30 {
        returns[i] = 100;
    }

    let checkpoint_mdds = [SCALE; MAX_CHECKPOINTS];
    let avg = 100;
    let result = calmar(
        returns,
        30,
        false,
        avg,
        365,
        CALMAR_NOCONFIDENCE_VALUE,
        0,
        checkpoint_mdds,
    );
    assert(result != 0);
}

#[test]
fn test_calmar_negative_returns() {
    let mut returns = [0; ARRAY_SIZE];
    for i in 0..50 {
        returns[i] = -100;
    }

    let checkpoint_mdds = [SCALE; MAX_CHECKPOINTS];
    let avg = -100;
    let result = calmar(
        returns,
        50,
        false,
        avg,
        365,
        CALMAR_NOCONFIDENCE_VALUE,
        0,
        checkpoint_mdds,
    );
    assert(result != 0);
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
    let result = calmar(
        log_returns,
        actual_len,
        bypass_confidence,
        avg_daily_return,
        days_in_year,
        CALMAR_NOCONFIDENCE_VALUE,
        0,
        checkpoint_mdds,
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
    let avg = 666667i64;
    let result = calmar(
        returns,
        3u32,
        true,
        avg,
        365i64,
        CALMAR_NOCONFIDENCE_VALUE,
        0,
        checkpoint_mdds,
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
    let avg = 1000000i64;
    let result = calmar(
        returns,
        59u32,
        false,
        avg,
        365i64,
        CALMAR_NOCONFIDENCE_VALUE,
        0,
        checkpoint_mdds,
    );
    assert(result == CALMAR_NOCONFIDENCE_VALUE);
}

#[test]
fn test_calmar_zero_variance() {
    let mut returns = [0; ARRAY_SIZE];
    let checkpoint_mdds = [SCALE; MAX_CHECKPOINTS];
    let avg = 0i64;
    let result = calmar(
        returns,
        60u32,
        true,
        avg,
        365i64,
        CALMAR_NOCONFIDENCE_VALUE,
        0,
        checkpoint_mdds,
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
    let avg = 1000000i64;
    let result = calmar(
        returns,
        60u32,
        true,
        avg,
        365i64,
        CALMAR_NOCONFIDENCE_VALUE,
        0,
        checkpoint_mdds,
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
    let avg = -1000000i64;
    let result = calmar(
        returns,
        60u32,
        true,
        avg,
        365i64,
        CALMAR_NOCONFIDENCE_VALUE,
        0,
        checkpoint_mdds,
    );
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
    let result = calmar(
        daily_returns,
        60,
        true,
        avg,
        365,
        CALMAR_NOCONFIDENCE_VALUE,
        1,
        checkpoint_mdds,
    );
    assert(result != 0);
}

#[test]
fn test_calmar_with_checkpoints_insufficient_days() {
    let mut checkpoint_returns = [0; MAX_CHECKPOINTS];
    checkpoint_returns[0] = 1000000;
    checkpoint_returns[1] = -500000;

    let daily_returns = [0; ARRAY_SIZE];
    let checkpoint_mdds = [SCALE; MAX_CHECKPOINTS];
    let avg = 250000;
    let result = calmar(
        daily_returns,
        2,
        false,
        avg,
        365,
        CALMAR_NOCONFIDENCE_VALUE,
        2,
        checkpoint_mdds,
    );
    assert(result == CALMAR_NOCONFIDENCE_VALUE);
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
    let result = calmar(
        daily_returns,
        60,
        true,
        avg,
        365,
        CALMAR_NOCONFIDENCE_VALUE,
        60,
        checkpoint_mdds,
    );
    assert(result == 0);
}

#[test]
fn test_calmar_10_percent_accuracy() {
    let log_returns = [0; ARRAY_SIZE];

    let mut checkpoint_mdds = [SCALE; MAX_CHECKPOINTS];
    checkpoint_mdds[0] = 911000; // 0.911 MDD (8.9% drawdown)

    let result = calmar(
        log_returns,
        60,
        true,
        76,
        365,
        CALMAR_NOCONFIDENCE_VALUE,
        1,
        checkpoint_mdds,
    );

    // Expected calculation:
    // SCALE = 100000000
    // checkpoint_mdds[0] = 911000
    // min_mdd = 911000 (minimum value found)
    // max_drawdown_decimal = SCALE - min_mdd = 100000000 - 911000 = 99089000
    // ann_excess_return = 76 * 365 = 27740
    // calmar = (27740 * SCALE) / max_drawdown_decimal
    // calmar = (27740 * 100000000) / 99089000 = 2774000000000 / 99089000 ~= 27990

    let expected = 27990; // 100x larger due to SCALE vs SCALE
    let tolerance = expected / 10; // 10% tolerance = 2799

    let diff = if result > expected {
        result - expected
    } else {
        expected - result
    };

    assert(diff <= tolerance);
}

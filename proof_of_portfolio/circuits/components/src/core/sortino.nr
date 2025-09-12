use crate::utils::{
    constants::{
        ARRAY_SIZE, SCALE, SORTINO_DOWNSIDE_MINIMUM, SORTINO_NOCONFIDENCE_VALUE,
        STATISTICAL_CONFIDENCE_MINIMUM_N,
    },
    sqrt::sqrt,
};

pub fn sortino(
    actual_len: u32,
    bypass_confidence: bool,
    downside_variance_val: i64,
    ann_excess_return_val: i64,
    noconfidence_value: i64,
) -> i64 {
    if !bypass_confidence & actual_len < STATISTICAL_CONFIDENCE_MINIMUM_N {
        noconfidence_value
    } else {
        let excess_return = ann_excess_return_val;

        let downside_volatility = if actual_len < 2 {
            SCALE
        } else {
            let scaled_annualized_downside_variance = (downside_variance_val as u64) * 365;
            let scaled_downside_volatility = sqrt(scaled_annualized_downside_variance);
            let scale_sqrt = sqrt(SCALE as u64);
            ((scaled_downside_volatility * (SCALE as u64) / scale_sqrt) as i64)
        };

        let effective_downside_volatility = if downside_volatility < SORTINO_DOWNSIDE_MINIMUM {
            SORTINO_DOWNSIDE_MINIMUM
        } else {
            downside_volatility
        };

        (excess_return * SCALE) / effective_downside_volatility
    }
}

#[test]
fn test_sortino_normal_case() {
    let mut returns = [0; ARRAY_SIZE];
    returns[0] = 1000;
    returns[1] = -500;
    returns[2] = 800;
    returns[3] = -300;
    returns[4] = 600;

    let downside_variance_val = 200000;
    let ann_excess = 116700;
    let result = sortino(
        5,
        false,
        downside_variance_val,
        ann_excess,
        SORTINO_NOCONFIDENCE_VALUE,
    );
    assert(result != 0);
}

#[test]
fn test_sortino_no_negative_returns() {
    let mut returns = [0; ARRAY_SIZE];
    for i in 0..5 {
        returns[i] = 1000;
    }

    let downside_variance_val = 0;
    let ann_excess = 365000;
    let result = sortino(
        5,
        false,
        downside_variance_val,
        ann_excess,
        SORTINO_NOCONFIDENCE_VALUE,
    );
    assert(result == SORTINO_NOCONFIDENCE_VALUE);
}

#[test]
fn test_sortino_all_negative_returns() {
    let mut returns = [0; ARRAY_SIZE];
    for i in 0..5 {
        returns[i] = -500;
    }

    let downside_variance_val = 1000;
    let ann_excess = -182500;
    let result = sortino(
        80,
        false,
        downside_variance_val,
        ann_excess,
        SORTINO_NOCONFIDENCE_VALUE,
    );

    let expected = -3021600;
    let tolerance = 1000;
    let diff = if result > expected {
        result - expected
    } else {
        expected - result
    };
    assert(diff <= tolerance);
}

#[test]
fn test_sortino_high_downside_volatility() {
    let mut returns = [0; ARRAY_SIZE];
    returns[0] = 2000;
    returns[1] = -1500;
    returns[2] = 1800;
    returns[3] = -1200;
    returns[4] = 1600;

    let downside_variance_val = 450000;
    let ann_excess = 218800;
    let result = sortino(
        5,
        false,
        downside_variance_val,
        ann_excess,
        SORTINO_NOCONFIDENCE_VALUE,
    );
    assert(result != 0);
}

#[test]
fn test_sortino_scaling() {
    let mut log_returns = [0; ARRAY_SIZE];
    log_returns[0] = SCALE / 100;
    log_returns[1] = -SCALE / 200;
    let actual_len = 60u32;
    let bypass_confidence = true;
    let downside_variance_val = SCALE / 1000;
    let ann_excess_return_val = SCALE / 100;
    let result = sortino(
        actual_len,
        bypass_confidence,
        downside_variance_val,
        ann_excess_return_val,
        SORTINO_NOCONFIDENCE_VALUE,
    );
    assert(result > 0);
}

#[test]
fn test_sortino_10_percent_accuracy() {
    let actual_len = 60u32;
    let bypass_confidence = true;

    let downside_variance_val = 9433;
    let ann_excess_return_val = 54082036;

    let result = sortino(
        actual_len,
        bypass_confidence,
        downside_variance_val,
        ann_excess_return_val,
        SORTINO_NOCONFIDENCE_VALUE,
    );

    let expected = 291460400;
    let tolerance = 1500000;

    let diff = if result > expected {
        result - expected
    } else {
        expected - result
    };

    assert(diff <= tolerance);
}

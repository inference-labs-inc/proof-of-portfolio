use crate::utils::{
    constants::{
        ARRAY_SIZE, SCALE, SHARPE_NOCONFIDENCE_VALUE, SHARPE_STDDEV_MINIMUM,
        STATISTICAL_CONFIDENCE_MINIMUM_N,
    },
    sqrt::sqrt,
};

pub fn sharpe(
    actual_len: u32,
    bypass_confidence: bool,
    variance_val: i64,
    ann_excess_return_val: i64,
    noconfidence_value: i64,
) -> i64 {
    let result = if !bypass_confidence & actual_len < STATISTICAL_CONFIDENCE_MINIMUM_N {
        noconfidence_value
    } else {
        let excess_return = ann_excess_return_val;
        let volatility = if actual_len < 2 {
            SCALE
        } else {
            let scaled_annualized_variance = (variance_val as u64) * 365;
            let scaled_volatility = sqrt(scaled_annualized_variance);
            let scale_sqrt = sqrt(SCALE as u64);
            ((scaled_volatility * (SCALE as u64) / scale_sqrt) as i64)
        };
        let effective_volatility = if volatility < SHARPE_STDDEV_MINIMUM {
            SHARPE_STDDEV_MINIMUM
        } else {
            volatility
        };

        (excess_return * SCALE) / effective_volatility
    };
    result
}

#[test]
fn test_sharpe_normal_case() {
    let mut returns = [0; ARRAY_SIZE];
    returns[0] = 1000;
    returns[1] = -500;
    returns[2] = 800;
    returns[3] = -300;
    returns[4] = 600;

    let variance_val = 200000;
    let ann_excess = 116700;
    let result = sharpe(
        5,
        false,
        variance_val,
        ann_excess,
        SHARPE_NOCONFIDENCE_VALUE,
    );
    assert(result != 0);
}

#[test]
fn test_sharpe_low_volatility() {
    let mut returns = [0; ARRAY_SIZE];
    for i in 0..10 {
        returns[i] = 50;
    }

    let variance_val = 0;
    let ann_excess = 18240;
    let result = sharpe(
        10,
        false,
        variance_val,
        ann_excess,
        SHARPE_NOCONFIDENCE_VALUE,
    );
    assert(result == SHARPE_NOCONFIDENCE_VALUE);
}

#[test]
fn test_sharpe_high_volatility() {
    let mut returns = [0; ARRAY_SIZE];
    returns[0] = 5000;
    returns[1] = -4000;
    returns[2] = 3000;
    returns[3] = -2000;
    returns[4] = 1000;

    let variance_val = 8400000;
    let ann_excess = 218800;
    let result = sharpe(
        5,
        false,
        variance_val,
        ann_excess,
        SHARPE_NOCONFIDENCE_VALUE,
    );
    assert(result != 0);
}

#[test]
fn test_sharpe_scaling() {
    let mut daily_returns = [0; ARRAY_SIZE];
    daily_returns[0] = SCALE / 100;
    let actual_len = 60u32;
    let bypass_confidence = true;
    let variance_val = SCALE / 100;
    let ann_excess_return_val = SCALE / 100;
    let result = sharpe(
        actual_len,
        bypass_confidence,
        variance_val,
        ann_excess_return_val,
        SHARPE_NOCONFIDENCE_VALUE,
    );
    assert(result > 0);
}

#[test]
fn test_sharpe_10_percent_accuracy() {
    let actual_len = 60u32;
    let bypass_confidence = true;

    let variance_val = 32444;
    let ann_excess_return_val = 54082036;

    let result = sharpe(
        actual_len,
        bypass_confidence,
        variance_val,
        ann_excess_return_val,
        SHARPE_NOCONFIDENCE_VALUE,
    );

    let expected = 158482900;
    let tolerance = 1500000;

    let diff = if result > expected {
        result - expected
    } else {
        expected - result
    };

    assert(diff <= tolerance);
}

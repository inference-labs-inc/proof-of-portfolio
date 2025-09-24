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
    minimum_n: u32,
) -> i64 {
    let result = if !bypass_confidence & actual_len < minimum_n {
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
        STATISTICAL_CONFIDENCE_MINIMUM_N,
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
        STATISTICAL_CONFIDENCE_MINIMUM_N,
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
        STATISTICAL_CONFIDENCE_MINIMUM_N,
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
        STATISTICAL_CONFIDENCE_MINIMUM_N,
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
        STATISTICAL_CONFIDENCE_MINIMUM_N,
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

#[test]
fn test_sharpe_bypass_confidence_true() {
    let actual_len = 30u32;
    let bypass_confidence = true;
    let variance_val = 301;
    let ann_excess = 21359999;

    let result = sharpe(
        actual_len,
        bypass_confidence,
        variance_val,
        ann_excess,
        SHARPE_NOCONFIDENCE_VALUE,
        STATISTICAL_CONFIDENCE_MINIMUM_N,
    );

    let expected = 655402844;
    let tolerance = 6554028;

    let diff = if result > expected {
        result - expected
    } else {
        expected - result
    };

    assert(diff <= tolerance);
}

#[test]
fn test_sharpe_bypass_confidence_false() {
    let actual_len = 30u32;
    let bypass_confidence = false;
    let variance_val = 25;
    let ann_excess = 1699166;

    let result = sharpe(
        actual_len,
        bypass_confidence,
        variance_val,
        ann_excess,
        SHARPE_NOCONFIDENCE_VALUE,
        STATISTICAL_CONFIDENCE_MINIMUM_N,
    );

    assert(result == SHARPE_NOCONFIDENCE_VALUE);
}

#[test]
fn test_sharpe_weighted_comprehensive() {
    let mut returns = [0; ARRAY_SIZE];

    let pattern =
        [200000, -100000, 150000, 300000, -200000, 100000, -50000, 250000, -150000, 200000];
    for i in 0..75 {
        returns[i] = pattern[i % 10];
    }

    let variance_val = 231;
    let ann_excess = 18001999;

    let result = sharpe(
        75,
        false,
        variance_val,
        ann_excess,
        SHARPE_NOCONFIDENCE_VALUE,
        STATISTICAL_CONFIDENCE_MINIMUM_N,
    );

    let expected = 619598798;
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
fn test_sharpe_comprehensive_high_volatility() {
    let mut returns = [0; ARRAY_SIZE];

    let pattern = [
        5000000, -4000000, 3000000, -6000000, 2000000, -3000000, 4000000, -2000000, 1000000,
        -5000000,
    ];
    for i in 0..80 {
        returns[i] = pattern[i % 10];
    }

    let variance_val = 144303;
    let ann_excess = -186689999;

    let result = sharpe(
        80,
        false,
        variance_val,
        ann_excess,
        SHARPE_NOCONFIDENCE_VALUE,
        STATISTICAL_CONFIDENCE_MINIMUM_N,
    );

    let expected = -258861337;
    let tolerance = 5000000;

    let diff = if result > expected {
        result - expected
    } else {
        expected - result
    };

    assert(diff <= tolerance);
}

#[test]
fn test_sharpe_edge_case_low_volatility() {
    let mut returns = [0; ARRAY_SIZE];

    for i in 0..65 {
        returns[i] = 10000;
    }

    let variance_val = 0;
    let ann_excess = 365000;

    let result = sharpe(
        65,
        false,
        variance_val,
        ann_excess,
        SHARPE_NOCONFIDENCE_VALUE,
        STATISTICAL_CONFIDENCE_MINIMUM_N,
    );

    let expected = 36500000;
    let tolerance = 1000000;

    let diff = if result > expected {
        result - expected
    } else {
        expected - result
    };

    assert(diff <= tolerance);
    assert(result > 0);
}

#[test]
fn test_sharpe_bypass_confidence_insufficient_samples() {
    let actual_len = 25u32;
    let bypass_confidence = true;
    let variance_val = 1225;
    let ann_excess = 10950000;

    let result = sharpe(
        actual_len,
        bypass_confidence,
        variance_val,
        ann_excess,
        SHARPE_NOCONFIDENCE_VALUE,
        STATISTICAL_CONFIDENCE_MINIMUM_N,
    );

    let expected = 177685950;
    let tolerance = 1000000;

    let diff = if result > expected {
        result - expected
    } else {
        expected - result
    };

    assert(diff <= tolerance);
    assert(result != SHARPE_NOCONFIDENCE_VALUE);
}

#[test]
fn test_sharpe_bypass_confidence_edge_case() {
    let actual_len = STATISTICAL_CONFIDENCE_MINIMUM_N;
    let variance_val = 625;
    let ann_excess = 12775000;

    let result_false = sharpe(
        actual_len,
        false,
        variance_val,
        ann_excess,
        SHARPE_NOCONFIDENCE_VALUE,
        STATISTICAL_CONFIDENCE_MINIMUM_N,
    );

    let result_true = sharpe(
        actual_len,
        true,
        variance_val,
        ann_excess,
        SHARPE_NOCONFIDENCE_VALUE,
        STATISTICAL_CONFIDENCE_MINIMUM_N,
    );

    assert(result_false == result_true);
    assert(result_false != SHARPE_NOCONFIDENCE_VALUE);
    assert(result_true != SHARPE_NOCONFIDENCE_VALUE);

    let expected = 290401435;
    let tolerance = 1000000;

    let diff = if result_true > expected {
        result_true - expected
    } else {
        expected - result_true
    };

    assert(diff <= tolerance);
}

#[test]
fn test_sharpe_bypass_confidence_negative_excess_return() {
    let actual_len = 20u32;
    let bypass_confidence = true;
    let variance_val = 2500;
    let ann_excess = -18250000;

    let result = sharpe(
        actual_len,
        bypass_confidence,
        variance_val,
        ann_excess,
        SHARPE_NOCONFIDENCE_VALUE,
        STATISTICAL_CONFIDENCE_MINIMUM_N,
    );

    let expected = -207123209;
    let tolerance = 1000000;

    let diff = if result > expected {
        result - expected
    } else {
        expected - result
    };

    assert(diff <= tolerance);
    assert(result < 0);
    assert(result != SHARPE_NOCONFIDENCE_VALUE);
}

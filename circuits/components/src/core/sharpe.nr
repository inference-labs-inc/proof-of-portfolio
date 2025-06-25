use crate::utils::{
    ann_excess_return::ann_excess_return,
    ann_volatility::ann_volatility,
    constants::{
        ARRAY_SIZE, SHARPE_NOCONFIDENCE_VALUE, SHARPE_SCALE_FACTOR, SHARPE_STDDEV_MINIMUM,
        STATISTICAL_CONFIDENCE_MINIMUM_N,
    },
};

pub fn sharpe(log_returns: [i64; ARRAY_SIZE], actual_len: u32, RISK_FREE_RATE: i64) -> i64 {
    // Check minimum sample size for statistical confidence
    if actual_len < STATISTICAL_CONFIDENCE_MINIMUM_N {
        SHARPE_NOCONFIDENCE_VALUE
    } else {
        let excess_return = ann_excess_return(log_returns, actual_len, RISK_FREE_RATE);
        let volatility = ann_volatility(log_returns, actual_len, 1);

        // Use minimum standard deviation to avoid division by zero/small numbers
        let effective_volatility = if volatility > SHARPE_STDDEV_MINIMUM {
            volatility
        } else {
            SHARPE_STDDEV_MINIMUM
        };

        (excess_return * SHARPE_SCALE_FACTOR) / effective_volatility
    }
}

#[test]
fn test_sharpe_normal_case() {
    let mut returns = [0; ARRAY_SIZE];
    returns[0] = 1000;
    returns[1] = -500;
    returns[2] = 800;
    returns[3] = -300;
    returns[4] = 600;

    let result = sharpe(returns, 5, 100);
    assert(result != 0);
}

#[test]
fn test_sharpe_low_volatility() {
    let mut returns = [0; ARRAY_SIZE];
    for i in 0..10 {
        returns[i] = 50;
    }

    let result = sharpe(returns, 10, 10);
    assert(result == 0);
}

#[test]
fn test_sharpe_high_volatility() {
    let mut returns = [0; ARRAY_SIZE];
    returns[0] = 5000;
    returns[1] = -4000;
    returns[2] = 3000;
    returns[3] = -2000;
    returns[4] = 1000;

    let result = sharpe(returns, 5, 200);
    assert(result != 0);
}

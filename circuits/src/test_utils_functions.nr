use components::utils::{
    ann_excess_return::ann_excess_return, ann_volatility::ann_volatility, average::average,
    variance::variance,
};
use components::utils::constants::ARRAY_SIZE;

#[test]
fn test_average() {
    let mut returns: [i64; ARRAY_SIZE] = [0; ARRAY_SIZE];

    // Test with positive numbers
    returns[0] = 100;
    returns[1] = 200;
    returns[2] = 300;
    let result = average(returns, 3);
    assert(result == 200); // (100 + 200 + 300) / 3 = 200

    // Test with negative numbers
    returns[0] = -100;
    returns[1] = -200;
    returns[2] = 100;
    let result2 = average(returns, 3);
    assert(result2 == -66); // (-100 + -200 + 100) / 3 = -66.67 rounded

    // Test with single element
    returns[0] = 500;
    let result3 = average(returns, 1);
    assert(result3 == 500);
}

#[test]
fn test_variance() {
    let mut returns: [i64; ARRAY_SIZE] = [0; ARRAY_SIZE];

    // Test with same values (zero variance)
    returns[0] = 100;
    returns[1] = 100;
    returns[2] = 100;
    let result = variance(returns, 3, 1);
    assert(result == 0);

    // Test with different values
    returns[0] = 100;
    returns[1] = 200;
    returns[2] = 300;
    let result2 = variance(returns, 3, 1);
    assert(result2 > 0);

    // Test with ddof = 0
    let result3 = variance(returns, 3, 0);
    assert(result3 > 0);
    assert(result3 != result2); // Should be different with different ddof
}

#[test]
fn test_ann_excess_return() {
    let mut returns: [i64; ARRAY_SIZE] = [0; ARRAY_SIZE];

    // Test with positive returns above risk-free rate
    for i in 0..12 {
        returns[i] = 200; // 2% per period
    }
    let result = ann_excess_return(returns, 12, 50); // 0.5% risk-free rate
    assert(result > 0); // Should be positive excess return

    // Test with returns below risk-free rate
    for i in 0..12 {
        returns[i] = 20; // 0.2% per period
    }
    let result2 = ann_excess_return(returns, 12, 50); // 0.5% risk-free rate
    assert(result2 < result); // Lower returns should give lower excess return

    // Test with zero risk-free rate
    returns[0] = 100;
    let result3 = ann_excess_return(returns, 1, 0);
    assert(result3 != 0);
}

#[test]
fn test_ann_volatility() {
    let mut returns: [i64; ARRAY_SIZE] = [0; ARRAY_SIZE];

    // Test with zero variance (same returns)
    for i in 0..12 {
        returns[i] = 150;
    }
    let result = ann_volatility(returns, 12, 1);
    assert(result == 0); // Zero volatility when all returns are same

    // Test with varying returns
    returns[0] = 100;
    returns[1] = 300;
    returns[2] = 50;
    returns[3] = 400;
    returns[4] = 200;
    returns[5] = 150;
    returns[6] = 350;
    returns[7] = 75;
    returns[8] = 250;
    returns[9] = 125;
    returns[10] = 300;
    returns[11] = 180;

    let result2 = ann_volatility(returns, 12, 1);
    assert(result2 > 0); // Should have positive volatility

    // Test with ddof = 0
    let result3 = ann_volatility(returns, 12, 0);
    assert(result3 > 0);
    assert(result3 != result2); // Different ddof should give different result
}

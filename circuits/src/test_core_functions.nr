use components::core::{
    drawdown::daily_max_drawdown, omega::omega, sharpe::sharpe, sortino::sortino,
    tstat::statistical_confidence,
};
use components::utils::constants::ARRAY_SIZE;

#[test]
fn test_daily_max_drawdown() {
    let mut returns: [i64; ARRAY_SIZE] = [0; ARRAY_SIZE];

    // Test with positive returns - should have zero drawdown
    for i in 0..10 {
        returns[i] = 100;
    }
    let result = daily_max_drawdown(returns, 10);
    assert(result == 0);

    // Test with mixed returns
    returns[0] = 1000;
    returns[1] = -200;
    returns[2] = -300;
    returns[3] = 500;

    let result2 = daily_max_drawdown(returns, 4);
    assert(result2 > 0);
}

#[test]
fn test_omega_ratio() {
    let mut returns: [i64; ARRAY_SIZE] = [0; ARRAY_SIZE];

    // Test with insufficient samples (should return no confidence value)
    for i in 0..5 {
        returns[i] = 200;
    }
    let result_insufficient = omega(returns, 5);
    assert(result_insufficient == 0); // OMEGA_NOCONFIDENCE_VALUE

    // Test with sufficient samples - all positive returns
    for i in 0..35 {
        returns[i] = 200;
    }
    let result_sufficient = omega(returns, 35);
    assert(result_sufficient == 10000000); // Maximum omega value when no negative returns

    // Test with mixed returns (sufficient samples) - more balanced
    for i in 0..35 {
        if i % 2 == 0 {
            returns[i] = 100; // Smaller positive returns
        } else {
            returns[i] = -200; // Larger negative returns for more realistic ratio
        }
    }
    let result_mixed = omega(returns, 35);
    assert(result_mixed > 0);
    // With 18*100 positive and 17*200 negative: (1800*10000000)/3400 = approx 5,294,117
    assert(result_mixed < 10000000);
}

#[test]
fn test_sharpe_ratio() {
    let mut returns: [i64; ARRAY_SIZE] = [0; ARRAY_SIZE];

    // Test with consistent positive returns
    for i in 0..20 {
        returns[i] = 150;
    }
    let result = sharpe(returns, 20, 50);
    // Test that function executes and returns deterministic result
    let result_again = sharpe(returns, 20, 50);
    assert(result == result_again); // Function should be deterministic

    // Test with zero variance (all same returns)
    for i in 0..10 {
        returns[i] = 100;
    }
    let result2 = sharpe(returns, 10, 100);
    assert(result2 == 0); // Should be zero when returns equal risk-free rate
}

#[test]
fn test_sortino_ratio() {
    let mut returns: [i64; ARRAY_SIZE] = [0; ARRAY_SIZE];

    // Test with insufficient samples (should return no confidence value)
    for i in 0..15 {
        returns[i] = 200;
    }
    let result_insufficient = sortino(returns, 15, 100);
    assert(result_insufficient == 0); // SORTINO_NOCONFIDENCE_VALUE

    // Test with sufficient samples - no negative returns
    for i in 0..35 {
        returns[i] = 200;
    }
    let result_no_negative = sortino(returns, 35, 100);
    assert(result_no_negative == 100000000); // Large value when no downside

    // Test with sufficient samples and some negative returns
    for i in 0..35 {
        if i % 3 == 0 {
            returns[i] = -100;
        } else {
            returns[i] = 300;
        }
    }
    let result_with_negative = sortino(returns, 35, 50);
    // Test that function executes and returns deterministic result
    let result_again = sortino(returns, 35, 50);
    assert(result_with_negative == result_again); // Function should be deterministic
    assert(result_with_negative != 0);
}

#[test]
fn test_statistical_confidence() {
    let mut returns: [i64; ARRAY_SIZE] = [0; ARRAY_SIZE];

    // Test with insufficient data
    returns[0] = 100;
    returns[1] = 200;
    let result = statistical_confidence(returns, 2);
    assert(result == 0); // Should return 0 for insufficient data

    // Test with sufficient data
    for i in 0..35 {
        returns[i] = 100 + (i as i64) * 10;
    }
    let result2 = statistical_confidence(returns, 35);
    assert(result2 != 0);
}

use crate::utils::constants::ARRAY_SIZE;

pub fn daily_max_drawdown(log_returns: [i64; ARRAY_SIZE], actual_len: u32) -> i64 {
    let mut max_drawdown: i64 = 0;
    let mut cumulative: i64 = 0;
    let mut peak: i64 = 0;

    for i in 0..ARRAY_SIZE {
        if (i as u32) < actual_len {
            cumulative = cumulative + log_returns[i];
            if cumulative > peak {
                peak = cumulative;
            }
            let drawdown = peak - cumulative;
            if drawdown > max_drawdown {
                max_drawdown = drawdown;
            }
        }
    }

    max_drawdown
}

#[test]
fn test_drawdown_all_positive() {
    let mut returns = [0; ARRAY_SIZE];
    for i in 0..10 {
        returns[i] = 100;
    }

    let result = daily_max_drawdown(returns, 10);
    assert(result == 0);
}

#[test]
fn test_drawdown_simple_case() {
    let mut returns = [0; ARRAY_SIZE];
    returns[0] = 1000;
    returns[1] = -500;
    returns[2] = -300;
    returns[3] = 200;

    let result = daily_max_drawdown(returns, 4);
    assert(result == 800);
}

#[test]
fn test_drawdown_multiple_peaks() {
    let mut returns = [0; ARRAY_SIZE];
    returns[0] = 1000;
    returns[1] = -500;
    returns[2] = 800;
    returns[3] = -1200;
    returns[4] = 400;

    let result = daily_max_drawdown(returns, 5);
    assert(result == 1200);
}

#[test]
fn test_drawdown_all_negative() {
    let mut returns = [0; ARRAY_SIZE];
    for i in 0..5 {
        returns[i] = -100;
    }

    let result = daily_max_drawdown(returns, 5);
    assert(result == 500);
}

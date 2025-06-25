use components::core::calmar::calmar;
use components::utils::constants::ARRAY_SIZE;

#[test]
fn test_calmar_basic() {
    let mut returns: [i64; ARRAY_SIZE] = [0; ARRAY_SIZE];

    returns[0] = 1000;
    returns[1] = -500;
    returns[2] = 800;

    let result_insufficient = calmar(returns, 3, 200);
    assert(result_insufficient == 0);

    for i in 0..40 {
        if i % 4 == 0 {
            returns[i] = -200;
        } else {
            returns[i] = 300;
        }
    }

    let result_normal = calmar(returns, 40, 100);
    assert(result_normal != 0);
}

#[test]
fn test_calmar_edge_cases_main() {
    let mut returns: [i64; ARRAY_SIZE] = [0; ARRAY_SIZE];

    for i in 0..30 {
        returns[i] = 400;
    }
    returns[15] = -300;

    let result_exactly_30 = calmar(returns, 30, 200);
    assert(result_exactly_30 != 0);

    let result_below_threshold = calmar(returns, 29, 200);
    assert(result_below_threshold == 0);

    let result_zero_rf = calmar(returns, 30, 0);
    assert(result_zero_rf != 0);
}

use crate::utils::constants::SCALE;

pub fn exp_scaled(x_scaled: i64) -> i64 {
    // Implements Taylor series for exp(x) = 1 + x + x^2/2! + x^3/3! + ...
    // This is for x <= 0
    let x_pow_2 = (x_scaled * x_scaled) / SCALE;
    let x_pow_3 = (x_pow_2 * x_scaled) / SCALE;
    let x_pow_4 = (x_pow_3 * x_scaled) / SCALE;
    let x_pow_5 = (x_pow_4 * x_scaled) / SCALE;

    let term1 = x_scaled;
    let term2 = x_pow_2 / 2;
    let term3 = x_pow_3 / 6;
    let term4 = x_pow_4 / 24;
    let term5 = x_pow_5 / 120;

    SCALE + term1 + term2 + term3 + term4 + term5
}

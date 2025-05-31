// miner_scoring.nr
// Implementation of miner scoring functions in Noir

mod miner_scoring {
    // Note: Since Noir works with integers, we use a fixed-point representation
    // with 4 decimal places (multiply by 10000)

    // Constants
    const SCALE: u64 = 10000; // Fixed-point scaling factor
    const RISK_FREE_RATE: u64 = 500; // Annual risk-free rate (5% * SCALE)
    const MIN_DRAWDOWN: u64 = 100; // Minimum drawdown (1% * SCALE)
    const MIN_VOLATILITY: u64 = 100; // Minimum volatility (1% * SCALE)
    const MIN_DOWNSIDE_DEVIATION: u64 = 100; // Minimum downside deviation (1% * SCALE)
    const MAX_DRAWDOWN_THRESHOLD: u64 = 1000; // Maximum allowed drawdown (10% * SCALE)

    // Function to calculate Calmar ratio: Annualized Return / Max Drawdown
    pub fn calculate_calmar_ratio(annualized_return: u64, max_drawdown: u64) -> u64 {
        // Avoid division by zero by using minimum drawdown
        let safe_drawdown = if max_drawdown < MIN_DRAWDOWN { MIN_DRAWDOWN } else { max_drawdown };

        // Calculate and return Calmar ratio (scaled)
        // We multiply by SCALE before division to maintain precision
        (annualized_return * SCALE) / safe_drawdown
    }

    // Function to calculate Sharpe ratio: (Annualized Return - Risk Free Rate) / Annualized Volatility
    pub fn calculate_sharpe_ratio(annualized_return: u64, annualized_volatility: u64) -> u64 {
        // Avoid division by zero by using minimum volatility
        let safe_volatility = if annualized_volatility < MIN_VOLATILITY { MIN_VOLATILITY } else { annualized_volatility };

        // Calculate and return Sharpe ratio (scaled)
        // We multiply by SCALE before division to maintain precision
        (annualized_return * SCALE) / safe_volatility
    }

    // Function to calculate Omega ratio: Sum of positive returns / Absolute sum of negative returns
    pub fn calculate_omega_ratio(positive_returns_sum: u64, negative_returns_sum: u64) -> u64 {
        // Avoid division by zero by using minimum negative returns
        let safe_negative_returns = if negative_returns_sum < MIN_DRAWDOWN { MIN_DRAWDOWN } else { negative_returns_sum };

        // Calculate and return Omega ratio (scaled)
        // We multiply by SCALE before division to maintain precision
        (positive_returns_sum * SCALE) / safe_negative_returns
    }

    // Function to calculate Sortino ratio: (Annualized Return - Risk Free Rate) / Annualized Downside Deviation
    pub fn calculate_sortino_ratio(annualized_return: u64, annualized_downside_deviation: u64) -> u64 {
        // Avoid division by zero by using minimum downside deviation
        let safe_downside_deviation = if annualized_downside_deviation < MIN_DOWNSIDE_DEVIATION { 
            MIN_DOWNSIDE_DEVIATION 
        } else { 
            annualized_downside_deviation 
        };

        // Calculate and return Sortino ratio (scaled)
        // We multiply by SCALE before division to maintain precision
        (annualized_return * SCALE) / safe_downside_deviation
    }

    // Function to calculate Statistical Confidence using t-statistic
    pub fn calculate_statistical_confidence(t_statistic: u64) -> u64 {
        // Normalize t-statistic to a score between 0 and 1
        // Higher t-statistic means higher confidence
        // t_statistic is already scaled by SCALE
        let max_t_stat = 10 * SCALE; // 10.0 scaled

        if t_statistic > max_t_stat {
            SCALE // 1.0 scaled (cap at 1.0)
        } else {
            // Divide by 10 (scaled)
            (t_statistic * SCALE) / max_t_stat
        }
    }

    // Main function to calculate the overall miner score
    pub fn calculate_miner_score(
        calmar_ratio: u64,
        sharpe_ratio: u64,
        omega_ratio: u64,
        sortino_ratio: u64,
        statistical_confidence: u64,
        max_drawdown: u64,
        risk_profile_penalty: u64
    ) -> u64 {
        // Check if max drawdown exceeds threshold
        if max_drawdown > MAX_DRAWDOWN_THRESHOLD {
            return 0;
        }

        // Calculate score with equal weights (20% each)
        // 20% = 0.20 = 2000 / 10000 in our fixed-point representation
        let weight = 2000; // 20% * SCALE
        let score = 
            (weight * calmar_ratio) / SCALE +
            (weight * sharpe_ratio) / SCALE +
            (weight * omega_ratio) / SCALE +
            (weight * sortino_ratio) / SCALE +
            (weight * statistical_confidence) / SCALE;

        // Apply risk profile penalty
        // penalty is scaled by SCALE (e.g., 0.5 = 5000)
        let penalty_factor = SCALE - risk_profile_penalty; // (1.0 - risk_profile_penalty) scaled
        let penalized_score = (score * penalty_factor) / SCALE;

        // Ensure score is not negative (should not happen with unsigned integers)
        penalized_score
    }
}

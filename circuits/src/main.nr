// main.nr
// Entry point for the Miner Scoring Noir project

use dep::std;

// Import the miner_scoring module
mod miner_scoring;
use miner_scoring::miner_scoring;

// Main function that will be called by the Noir CLI
fn main(
    annualized_return: u64,
    max_drawdown: u64,
    annualized_volatility: u64,
    positive_returns_sum: u64,
    negative_returns_sum: u64,
    annualized_downside_deviation: u64,
    t_statistic: u64,
    risk_profile_penalty: u64
) -> pub u64 {
    // Calculate individual metrics
    let calmar_ratio = miner_scoring::calculate_calmar_ratio(
        annualized_return, max_drawdown
    );
    
    let sharpe_ratio = miner_scoring::calculate_sharpe_ratio(
        annualized_return, annualized_volatility
    );
    
    let omega_ratio = miner_scoring::calculate_omega_ratio(
        positive_returns_sum, negative_returns_sum
    );
    
    let sortino_ratio = miner_scoring::calculate_sortino_ratio(
        annualized_return, annualized_downside_deviation
    );
    
    let statistical_confidence = miner_scoring::calculate_statistical_confidence(
        t_statistic
    );
    
    // Calculate and return the final score
    miner_scoring::calculate_miner_score(
        calmar_ratio,
        sharpe_ratio,
        omega_ratio,
        sortino_ratio,
        statistical_confidence,
        max_drawdown,
        risk_profile_penalty
    )
}
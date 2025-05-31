#!/usr/bin/env python3
"""
test_noir_scoring.py

This script demonstrates how to use the Noir interface to calculate miner scores.
It uses the Noir CLI to generate and verify actual zero-knowledge proofs.
"""

import os
import sys
import json
from pathlib import Path
import numpy as np
from main import Main
from noir_interface import NoirMinerScoring, float_to_fixed, fixed_to_float

def test_with_sample_data():
    """Test the Noir scoring functions with sample data"""
    print("Testing Noir scoring functions with sample data...")

    # Sample data (these would typically come from actual miner data)
    annualized_return = 0.15  # 15% annual return
    max_drawdown = 0.05  # 5% maximum drawdown
    annualized_volatility = 0.08  # 8% volatility
    positive_returns_sum = 0.25  # Sum of positive returns
    negative_returns_sum = 0.10  # Sum of negative returns
    annualized_downside_deviation = 0.06  # 6% downside deviation
    t_statistic = 2.5  # t-statistic value
    risk_profile_penalty = 0.2  # 20% risk profile penalty

    # Convert to fixed-point representation
    fixed_annualized_return = float_to_fixed(annualized_return)
    fixed_max_drawdown = float_to_fixed(max_drawdown)
    fixed_annualized_volatility = float_to_fixed(annualized_volatility)
    fixed_positive_returns_sum = float_to_fixed(positive_returns_sum)
    fixed_negative_returns_sum = float_to_fixed(negative_returns_sum)
    fixed_annualized_downside_deviation = float_to_fixed(annualized_downside_deviation)
    fixed_t_statistic = float_to_fixed(t_statistic)
    fixed_risk_profile_penalty = float_to_fixed(risk_profile_penalty)

    # Calculate individual metrics
    fixed_calmar_ratio = NoirMinerScoring.calculate_calmar_ratio(
        fixed_annualized_return, fixed_max_drawdown
    )
    fixed_sharpe_ratio = NoirMinerScoring.calculate_sharpe_ratio(
        fixed_annualized_return, fixed_annualized_volatility
    )
    fixed_omega_ratio = NoirMinerScoring.calculate_omega_ratio(
        fixed_positive_returns_sum, fixed_negative_returns_sum
    )
    fixed_sortino_ratio = NoirMinerScoring.calculate_sortino_ratio(
        fixed_annualized_return, fixed_annualized_downside_deviation
    )
    fixed_statistical_confidence = NoirMinerScoring.calculate_statistical_confidence(
        fixed_t_statistic
    )

    # Calculate overall score
    fixed_score = NoirMinerScoring.calculate_miner_score(
        fixed_calmar_ratio,
        fixed_sharpe_ratio,
        fixed_omega_ratio,
        fixed_sortino_ratio,
        fixed_statistical_confidence,
        fixed_max_drawdown,
        fixed_risk_profile_penalty
    )

    # Convert back to floating point for display
    calmar_ratio = fixed_to_float(fixed_calmar_ratio)
    sharpe_ratio = fixed_to_float(fixed_sharpe_ratio)
    omega_ratio = fixed_to_float(fixed_omega_ratio)
    sortino_ratio = fixed_to_float(fixed_sortino_ratio)
    statistical_confidence = fixed_to_float(fixed_statistical_confidence)
    score = fixed_to_float(fixed_score)

    # Display results
    print(f"\nInput values:")
    print(f"  Annualized Return: {annualized_return:.4f}")
    print(f"  Max Drawdown: {max_drawdown:.4f}")
    print(f"  Annualized Volatility: {annualized_volatility:.4f}")
    print(f"  Positive Returns Sum: {positive_returns_sum:.4f}")
    print(f"  Negative Returns Sum: {negative_returns_sum:.4f}")
    print(f"  Annualized Downside Deviation: {annualized_downside_deviation:.4f}")
    print(f"  T-Statistic: {t_statistic:.4f}")
    print(f"  Risk Profile Penalty: {risk_profile_penalty:.4f}")

    print(f"\nCalculated metrics:")
    print(f"  Calmar Ratio: {calmar_ratio:.4f}")
    print(f"  Sharpe Ratio: {sharpe_ratio:.4f}")
    print(f"  Omega Ratio: {omega_ratio:.4f}")
    print(f"  Sortino Ratio: {sortino_ratio:.4f}")
    print(f"  Statistical Confidence: {statistical_confidence:.4f}")

    print(f"\nFinal Score: {score:.4f}")

def test_with_real_miner_data():
    """Test the Noir scoring functions with real miner data"""
    print("\nTesting Noir scoring functions with real miner data...")

    # Create an instance of the Main class to access miner data
    main_instance = Main()

    # Check if children directory exists
    if not main_instance.children_dir.exists():
        print(f"Children directory not found: {main_instance.children_dir}")
        return

    # Get the first miner file
    miner_files = list(main_instance.children_dir.glob("*.json"))
    if not miner_files:
        print("No miner files found")
        return

    miner_file = miner_files[0]
    miner_hotkey = miner_file.stem
    print(f"Testing with miner: {miner_hotkey}")

    # Load miner data
    try:
        with open(miner_file, 'r') as f:
            positions = json.load(f)
    except Exception as e:
        print(f"Error loading data for miner {miner_hotkey}: {e}")
        return

    # Calculate daily returns
    daily_returns = main_instance._calculate_daily_returns(positions)

    # Calculate metrics using the Python implementation
    python_score = main_instance.get_miner_score(miner_hotkey)
    print(f"Python implementation score: {python_score:.4f}")

    # For demonstration purposes, we'll calculate a simplified score using the Noir interface
    # In a real implementation, we would extract all the necessary metrics from the miner data
    # and pass them to the Noir functions

    # Simplified example (using dummy values for demonstration)
    annualized_return = 0.12
    max_drawdown = 0.04
    risk_profile_penalty = 0.1

    # Convert to fixed-point
    fixed_annualized_return = float_to_fixed(annualized_return)
    fixed_max_drawdown = float_to_fixed(max_drawdown)
    fixed_risk_profile_penalty = float_to_fixed(risk_profile_penalty)

    # Calculate a simplified score
    fixed_calmar_ratio = NoirMinerScoring.calculate_calmar_ratio(
        fixed_annualized_return, fixed_max_drawdown
    )

    # Convert back to floating point
    noir_score = fixed_to_float(fixed_calmar_ratio)
    print(f"Noir interface simplified score: {noir_score:.4f}")

    print("\nNote: This is a simplified demonstration. In a real implementation,")
    print("we would extract all metrics from the miner data and pass them to the Noir functions.")

def test_with_noir_cli():
    """Test using the Noir CLI directly"""
    print("\nTesting using the Noir CLI directly...")

    # Sample data (these would typically come from actual miner data)
    annualized_return = 0.15  # 15% annual return
    max_drawdown = 0.05  # 5% maximum drawdown
    annualized_volatility = 0.08  # 8% volatility
    positive_returns_sum = 0.25  # Sum of positive returns
    negative_returns_sum = 0.10  # Sum of negative returns
    annualized_downside_deviation = 0.06  # 6% downside deviation
    t_statistic = 2.5  # t-statistic value
    risk_profile_penalty = 0.2  # 20% risk profile penalty

    # Convert to fixed-point representation
    fixed_annualized_return = float_to_fixed(annualized_return)
    fixed_max_drawdown = float_to_fixed(max_drawdown)
    fixed_annualized_volatility = float_to_fixed(annualized_volatility)
    fixed_positive_returns_sum = float_to_fixed(positive_returns_sum)
    fixed_negative_returns_sum = float_to_fixed(negative_returns_sum)
    fixed_annualized_downside_deviation = float_to_fixed(annualized_downside_deviation)
    fixed_t_statistic = float_to_fixed(t_statistic)
    fixed_risk_profile_penalty = float_to_fixed(risk_profile_penalty)

    # Create input data for the Noir circuit
    input_data = {
        "annualized_return": fixed_annualized_return,
        "max_drawdown": fixed_max_drawdown,
        "annualized_volatility": fixed_annualized_volatility,
        "positive_returns_sum": fixed_positive_returns_sum,
        "negative_returns_sum": fixed_negative_returns_sum,
        "annualized_downside_deviation": fixed_annualized_downside_deviation,
        "t_statistic": fixed_t_statistic,
        "risk_profile_penalty": fixed_risk_profile_penalty
    }

    try:
        # Run the Noir circuit
        print("Running Noir circuit with sample data...")
        result = NoirMinerScoring.run_noir_circuit(input_data)

        # Convert back to floating point for display
        score = fixed_to_float(result)
        print(f"Noir CLI result: {score:.4f}")
    except Exception as e:
        print(f"Error running Noir circuit: {e}")
        print("Note: This test requires the Noir toolchain to be installed.")
        print("See README_noir_interface.md for installation instructions.")

if __name__ == "__main__":
    # Test with sample data
    test_with_sample_data()

    # Test with real miner data (simplified)
    test_with_real_miner_data()

    # Test with Noir CLI
    test_with_noir_cli()

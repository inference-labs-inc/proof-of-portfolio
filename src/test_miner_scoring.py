#!/usr/bin/env python3
"""
test_miner_scoring.py

This script tests the miner scoring functions implemented in main.py.
It calculates scores for all miners and displays the results.
"""

import os
import sys
from pathlib import Path
from main import Main

def main():
    # Create an instance of the Main class
    main_instance = Main()
    
    # Get scores for all miners
    print("Calculating scores for all miners...")
    all_scores = main_instance.get_all_scores()
    
    # Display results
    if not all_scores:
        print("No miner scores calculated. Check if data/children directory exists and contains miner data.")
        return
    
    print(f"\nFound scores for {len(all_scores)} miners:")
    
    # Sort miners by score (highest first)
    sorted_miners = sorted(all_scores.items(), key=lambda x: x[1], reverse=True)
    
    # Display top 10 miners
    print("\nTop 10 miners by score:")
    for i, (hotkey, score) in enumerate(sorted_miners[:10], 1):
        print(f"{i}. {hotkey[:10]}...{hotkey[-5:]}: {score:.6f}")
    
    # Calculate some statistics
    if sorted_miners:
        highest_score = sorted_miners[0][1]
        lowest_score = sorted_miners[-1][1]
        avg_score = sum(score for _, score in sorted_miners) / len(sorted_miners)
        
        print(f"\nScore Statistics:")
        print(f"Highest score: {highest_score:.6f}")
        print(f"Lowest score: {lowest_score:.6f}")
        print(f"Average score: {avg_score:.6f}")
    
    # Test a specific miner if available
    if sorted_miners:
        # Get the top miner for detailed testing
        top_miner = sorted_miners[0][0]
        print(f"\nDetailed score calculation for top miner {top_miner}:")
        
        # Calculate score for this specific miner
        score = main_instance.get_miner_score(top_miner)
        print(f"Final score: {score:.6f}")

if __name__ == "__main__":
    main()
#!/usr/bin/env python3
"""
analyse_data.py

This script takes data from data/input_data.json and creates a folder called 'children'
inside the data directory which contains all the trades based on unique hotkeys/users.

Each user's trades are saved to a separate JSON file named after their hotkey.
"""

import json
import os
import sys
from pathlib import Path

def main():
    # Path to the input data file
    input_file = Path("data/input_data.json")

    # Check if the input file exists
    if not input_file.exists():
        print(f"Error: Input file {input_file} does not exist.")
        sys.exit(1)

    # Read the JSON data
    try:
        with open(input_file, 'r') as f:
            data = json.load(f)
    except json.JSONDecodeError as e:
        print(f"Error: Failed to parse JSON data: {e}")
        sys.exit(1)
    except Exception as e:
        print(f"Error: Failed to read input file: {e}")
        sys.exit(1)

    # Print the top-level keys to understand the structure
    print("Top-level keys in the JSON data:")
    for key in data.keys():
        print(f"- {key}")

    # Examine the structure of positions and perf_ledgers
    print("\nExamining 'positions' structure:")
    if 'positions' in data:
        positions = data['positions']
        if isinstance(positions, dict):
            print(f"'positions' is a dictionary with {len(positions)} keys")
            # Print a sample key
            if positions:
                sample_key = next(iter(positions))
                print(f"Sample key: {sample_key}")
                print(f"Sample value type: {type(positions[sample_key])}")
                # Print structure of the sample value
                sample_value = positions[sample_key]
                if isinstance(sample_value, dict):
                    print(f"Sample value keys: {list(sample_value.keys())}")
                    # Examine the nested 'positions' key if it exists
                    if 'positions' in sample_value:
                        nested_positions = sample_value['positions']
                        print(f"Nested 'positions' type: {type(nested_positions)}")
                        if isinstance(nested_positions, dict):
                            print(f"Nested 'positions' is a dictionary with {len(nested_positions)} keys")
                            if nested_positions:
                                nested_sample_key = next(iter(nested_positions))
                                print(f"Nested sample key: {nested_sample_key}")
                                print(f"Nested sample value type: {type(nested_positions[nested_sample_key])}")
                                if isinstance(nested_positions[nested_sample_key], dict):
                                    print(f"Nested sample value keys: {list(nested_positions[nested_sample_key].keys())}")
                        elif isinstance(nested_positions, list):
                            print(f"Nested 'positions' is a list with {len(nested_positions)} items")
                            if nested_positions:
                                print(f"First nested item type: {type(nested_positions[0])}")
                                if isinstance(nested_positions[0], dict):
                                    print(f"First nested item keys: {list(nested_positions[0].keys())}")
        elif isinstance(positions, list):
            print(f"'positions' is a list with {len(positions)} items")
            if positions:
                print(f"First item type: {type(positions[0])}")
                if isinstance(positions[0], dict):
                    print(f"First item keys: {list(positions[0].keys())}")

    print("\nExamining 'perf_ledgers' structure:")
    if 'perf_ledgers' in data:
        perf_ledgers = data['perf_ledgers']
        if isinstance(perf_ledgers, dict):
            print(f"'perf_ledgers' is a dictionary with {len(perf_ledgers)} keys")
            # Print a sample key
            if perf_ledgers:
                sample_key = next(iter(perf_ledgers))
                print(f"Sample key: {sample_key}")
                print(f"Sample value type: {type(perf_ledgers[sample_key])}")
                # Print structure of the sample value
                sample_value = perf_ledgers[sample_key]
                if isinstance(sample_value, dict):
                    print(f"Sample value keys: {list(sample_value.keys())}")
        elif isinstance(perf_ledgers, list):
            print(f"'perf_ledgers' is a list with {len(perf_ledgers)} items")
            if perf_ledgers:
                print(f"First item type: {type(perf_ledgers[0])}")
                if isinstance(perf_ledgers[0], dict):
                    print(f"First item keys: {list(perf_ledgers[0].keys())}")

    # Create the children directory inside the data folder if it doesn't exist
    children_dir = Path("data/children")
    if not children_dir.exists():
        children_dir.mkdir(parents=True)
        print(f"Created directory: {children_dir}")

    # Process the data to group trades by hotkeys/users
    print("\nProcessing trades by hotkeys/users...")

    if 'positions' in data:
        positions_data = data['positions']
        count = 0

        for hotkey, user_data in positions_data.items():
            # Extract the user's trades (nested 'positions' list)
            if 'positions' in user_data and isinstance(user_data['positions'], list):
                user_trades = user_data['positions']

                # Create a file for this user's trades
                user_file = children_dir / f"{hotkey}.json"

                try:
                    with open(user_file, 'w') as f:
                        # Save the user's trades as JSON
                        json.dump(user_trades, f, indent=2)
                    count += 1
                except Exception as e:
                    print(f"Error saving trades for hotkey {hotkey}: {e}")

        print(f"Successfully saved trades for {count} hotkeys/users in the 'data/children' directory.")

if __name__ == "__main__":
    main()

#!/usr/bin/env python3
"""
analyse_data.py

This script takes data from data/input.json and creates a folder called 'children'
inside the data directory which contains all the trades based on unique hotkeys/users.

Each user's trades are saved to a separate JSON file named data.json in a directory
named after their hotkey (children/{hotkey}/data.json).
"""

import json
import os
import sys
from pathlib import Path

def split_input_json(input_file_path: str = "../data/input_data.json", output_dir: str = "../data/children"):
    """
    Splits the input JSON file into separate files for each hotkey.

    Args:
        input_file_path (str): Path to the input JSON file
        output_dir (str): Directory where the split files will be saved

    Returns:
        int: Number of hotkeys processed
    """
    # Convert to Path objects
    input_file = Path(input_file_path)
    children_dir = Path(output_dir)

    # Check if the input file exists
    if not input_file.exists():
        print(f"Error: Input file {input_file} does not exist.")
        return 0

    # Read the JSON data
    try:
        with open(input_file, 'r') as f:
            data = json.load(f)
    except json.JSONDecodeError as e:
        print(f"Error: Failed to parse JSON data: {e}")
        return 0
    except Exception as e:
        print(f"Error: Failed to read input file: {e}")
        return 0

    # Create the children directory if it doesn't exist
    if not children_dir.exists():
        children_dir.mkdir(parents=True)
        print(f"Created directory: {children_dir}")

    # Process the data to group trades by hotkeys/users
    print(f"Processing trades by hotkeys/users from {input_file}...")

    count = 0
    if 'positions' in data:
        positions_data = data['positions']

        for hotkey, user_data in positions_data.items():
            # Extract the user's trades (nested 'positions' list)
            if 'positions' in user_data and isinstance(user_data['positions'], list):
                user_trades = user_data['positions']

                # Create a directory for this user
                user_dir = children_dir / hotkey
                if not user_dir.exists():
                    user_dir.mkdir(parents=True)

                # Create a file for this user's trades
                user_file = user_dir / "data.json"

                try:
                    with open(user_file, 'w') as f:
                        # Save the user's trades as JSON
                        json.dump(user_trades, f, indent=2)
                    count += 1
                except Exception as e:
                    print(f"Error saving trades for hotkey {hotkey}: {e}")

    print(f"Successfully saved trades for {count} hotkeys/users in the '{output_dir}' directory.")
    return count

def main():
    # Split the input JSON file
    split_input_json()

if __name__ == "__main__":
    main()

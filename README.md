# Proof of Portfolio

This project provides tools for analyzing and scoring miner portfolios using both Python and Noir (for zero-knowledge proofs).

## Overview

The Proof of Portfolio project allows you to:

1. Analyze trading data from miners
2. Calculate performance metrics (Calmar ratio, Sharpe ratio, etc.)
3. Generate an overall score for each miner
4. Create zero-knowledge proofs of the scoring calculations using Noir

## Getting Started

### Prerequisites

- Python 3.7+
- Node.js and npm (for Noir CLI)
- Noir toolchain (see [Noir Interface README](README_noir_interface.md) for installation instructions)

## Usage

### 1. Input Data

Place your miner data files in the `data/children` directory. Each file should be a JSON file named with the miner's hotkey as the filename (e.g., `5CcNVDt7YLa8YbyUJxS7TZ9y5gsR3qNq3rbKGU6B4A4H541W.json`).

The JSON files should contain an array of position objects with the following structure:

```json
[
  {
    "is_closed_position": true,
    "close_ms": 1625097600000,
    "return_at_close": 1.05,
    ...
  },
  ...
]
```

### 2. Analyze Data

To analyze the data and calculate scores for all miners:

```python
from main import Main

# Create an instance of the Main class
main = Main()

# Get scores for all miners
scores = main.get_all_scores()

# Print the scores
for miner_hotkey, score in scores.items():
    print(f"{miner_hotkey}: {score:.4f}")
```

### 3. Test Scores in Python

You can run the test script to see how the scoring functions work:

```bash
python src/test_noir_scoring.py
```

This will:
- Test the scoring functions with sample data
- Test with real miner data (simplified)
- Test using the Noir CLI (if installed)

### 4. Use the Noir CLI

For generating and verifying zero-knowledge proofs of the scoring calculations, you can use the Noir CLI. See the [Noir Interface README](README_noir_interface.md) for detailed instructions.

Basic usage:

```bash
# Compile the circuit
cd circuits
nargo compile

# Generate a proof
nargo prove

# Verify a proof
nargo verify
```

## Project Structure

- `src/` - Python source code
  - `main.py` - Main analysis functions
  - `noir_interface.py` - Interface to the Noir implementation
  - `test_noir_scoring.py` - Test script for the scoring functions
- `circuits/` - Noir implementation
  - `src/main.nr` - Main entry point for the Noir circuit
  - `src/miner_scoring/miner_scoring.nr` - Scoring functions implementation
  - `Nargo.toml` - Noir project configuration
  - `Prover.toml` - Sample inputs for testing
- `data/` - Data directory
  - `children/` - Miner data files

## Documentation

- [Noir Interface README](README_noir_interface.md) - Detailed documentation on the Noir interface and CLI usage
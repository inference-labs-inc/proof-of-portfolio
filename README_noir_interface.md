# Noir Interface for Miner Scoring

This project provides a Python interface to the Noir miner scoring functions, allowing you to generate and verify actual zero-knowledge proofs using the Noir CLI.

## Overview

The implementation consists of:

1. **Noir Implementation** (`circuits/`): The scoring functions implemented in Noir.
   - `circuits/src/main.nr`: The main entry point for the Noir circuit.
   - `circuits/src/miner_scoring/miner_scoring.nr`: The scoring functions implementation.
   - `circuits/Nargo.toml`: The Noir project configuration file.
   - `circuits/Prover.toml`: Sample inputs for testing the Noir circuit.

2. **Python Interface** (`src/noir_interface.py`): A Python interface that uses the Noir CLI to generate and verify proofs.

3. **Test Script** (`src/test_noir_scoring.py`): A script that demonstrates how to use the interface.

## How It Works

The Python interface uses the Noir CLI to compile the Noir code, generate proofs, and verify them. This allows for actual zero-knowledge proof generation and verification, rather than just simulating the behavior in Python.

The interface still uses the same fixed-point arithmetic approach as the Noir code, with a scaling factor of 10000 to handle decimal values (since Noir works with integers).

## Prerequisites

Before using this interface, you need to install the Noir toolchain:

1. **Install Noir**:
   ```bash
   # Using npm
   npm install -g @noir-lang/noir_js

   # Or using yarn
   yarn global add @noir-lang/noir_js
   ```

2. **Verify Installation**:
   ```bash
   nargo --version
   ```

## Usage

### Basic Usage

```python
from noir_interface import NoirMinerScoring, float_to_fixed, fixed_to_float

# Convert floating-point values to fixed-point representation
fixed_annualized_return = float_to_fixed(0.15)  # 15% annual return
fixed_max_drawdown = float_to_fixed(0.05)  # 5% maximum drawdown

# Calculate Calmar ratio
fixed_calmar_ratio = NoirMinerScoring.calculate_calmar_ratio(
    fixed_annualized_return, fixed_max_drawdown
)

# Convert back to floating point for display
calmar_ratio = fixed_to_float(fixed_calmar_ratio)
print(f"Calmar Ratio: {calmar_ratio:.4f}")
```

### Running the Test Script

To run the test script:

```bash
python src/test_noir_scoring.py
```

This will:
1. Test the Noir scoring functions with sample data
2. Attempt to test with real miner data (simplified)

## Using the Noir CLI Directly

You can also use the Noir CLI directly to work with the circuit:

### Compile the Circuit

```bash
cd circuits
nargo compile
```

### Generate a Proof

```bash
cd circuits
nargo prove
```

This will use the inputs defined in `Prover.toml` to generate a proof.

### Verify a Proof

```bash
cd circuits
nargo verify
```

### Custom Inputs

You can provide custom inputs by creating a JSON file:

```json
{
  "annualized_return": 1500,
  "max_drawdown": 500,
  "annualized_volatility": 800,
  "positive_returns_sum": 2500,
  "negative_returns_sum": 1000,
  "annualized_downside_deviation": 600,
  "t_statistic": 25000,
  "risk_profile_penalty": 2000
}
```

Then use it with the Noir CLI:

```bash
cd circuits
nargo prove --input my_inputs.json --output my_proof.json
nargo verify --proof my_proof.json
```

## Functions

The interface provides the following functions:

### Scoring Functions

- `calculate_calmar_ratio(annualized_return, max_drawdown)`: Calculate Calmar ratio
- `calculate_sharpe_ratio(annualized_return, annualized_volatility)`: Calculate Sharpe ratio
- `calculate_omega_ratio(positive_returns_sum, negative_returns_sum)`: Calculate Omega ratio
- `calculate_sortino_ratio(annualized_return, annualized_downside_deviation)`: Calculate Sortino ratio
- `calculate_statistical_confidence(t_statistic)`: Calculate Statistical Confidence
- `calculate_miner_score(calmar_ratio, sharpe_ratio, omega_ratio, sortino_ratio, statistical_confidence, max_drawdown, risk_profile_penalty)`: Calculate the overall miner score

### Helper Functions

- `float_to_fixed(value)`: Convert a floating-point value to fixed-point representation
- `fixed_to_float(value)`: Convert a fixed-point value back to floating-point
- `run_noir_circuit(input_data)`: Run the Noir circuit with the given input data

## Constants

The interface uses the following constants:

- `SCALE = 10000`: Fixed-point scaling factor
- `RISK_FREE_RATE = 500`: Annual risk-free rate (5% * SCALE)
- `MIN_DRAWDOWN = 100`: Minimum drawdown (1% * SCALE)
- `MIN_VOLATILITY = 100`: Minimum volatility (1% * SCALE)
- `MIN_DOWNSIDE_DEVIATION = 100`: Minimum downside deviation (1% * SCALE)
- `MAX_DRAWDOWN_THRESHOLD = 1000`: Maximum allowed drawdown (10% * SCALE)

## Troubleshooting

If you encounter issues with the Noir CLI:

1. **Check Noir Installation**: Make sure Noir is installed correctly and the `nargo` command is available in your PATH.
2. **Check Circuit Path**: Make sure the circuit path in `NoirMinerScoring.CIRCUIT_PATH` is correct.
3. **Check Input Format**: Make sure the input data is in the correct format and all required fields are present.
4. **Check Error Messages**: The interface will raise exceptions with error messages from the Noir CLI if something goes wrong.

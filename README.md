# Proof of Portfolio

A zero-knowledge proof system for privacy-preserving trading performance verification. This project enables miners to prove their trading performance using sophisticated financial metrics without revealing sensitive trading data. It also allows validators to publish records of miners' performance without revealing the miners' identities or their trading data.

## Features

- **Privacy-Preserving Verification**: Prove trading performance without revealing individual trades
- **Sophisticated Financial Metrics**: 5 industry-standard performance calculations
- **Merkle Tree Inclusion Proofs**: Cryptographic verification of trading signal authenticity

## Financial Metrics

The system calculates 5 sophisticated trading performance metrics:

1. **Calmar Ratio**: Risk-adjusted return considering maximum drawdown
2. **Sharpe Ratio**: Return per unit of volatility risk
3. **Omega Ratio**: Probability-weighted ratio of gains vs losses
4. **Sortino Ratio**: Downside deviation-adjusted returns
5. **Statistical Confidence**: T-statistic based confidence measure

All calculations are performed from raw daily returns, ensuring mathematical integrity.

## Getting Started

### Prerequisites

- [Noir](https://noir-lang.org/) - Zero-knowledge proof framework
- Python 3.7+ (for input generation)

### Installation

#### Option 1: Using the install script (Recommended)

The project includes an installation script that will set up all required dependencies:

```bash
# Clone the repository
git clone https://github.com/inference-labs-inc/proof-of-portfolio
cd proof-of-portfolio

# Make the script executable
chmod +x install.sh

# Run the installation script (interactive mode)
./install.sh
```

The script supports various options:

```bash
# Install all dependencies without prompts
./install.sh --all

# Install specific dependencies
./install.sh --with-bignum --with-barretenberg

# Show help
./install.sh --help
```

#### Option 2: Manual Installation

If you prefer to install dependencies manually:

1. Install Noir:

```bash
curl -L https://raw.githubusercontent.com/noir-lang/noirup/main/install | bash
noirup
```

2. Clone and navigate to the project:

```bash
git clone https://github.com/inference-labs-inc/proof-of-portfolio
cd proof-of-portfolio/circuits
```

## Usage

### 1. Generate Test Inputs

```bash
python3 generate_inputs.py
```

This creates `Prover.toml` with test trading signals and proper Merkle tree data.

### 2. Execute the Circuit

```bash
nargo execute
```

This runs the circuit and outputs:

- Trading performance score
- Merkle verification status (true/false)

### 3. Run Tests

```bash
nargo test
```

### 4. Generate Proof

For proving, the Barretenberg backend is used:

```bash
# Compile to ACIR first
nargo compile

# Generate proof using Barretenberg (requires additional setup)
bb prove -b ./target/miner_scoring.json -w ./target/miner_scoring.gz -o ./proof
bb write_vk -b ./target/miner_scoring.json -o ./vk
bb verify -k ./vk -p ./proof
```

> [!NOTE]
> Proof generation requires the Barretenberg proving system to be installed separately.

## Circuit Architecture

### Input Structure

| Name              | Type                 | Description                                                      |
| ----------------- | -------------------- | ---------------------------------------------------------------- |
| `trading_signals` | `Vec<TradingSignal>` | Array of trading data (miner_hotkey, trade_pair_id, price, etc.) |
| `merkle_proofs`   | `Vec<MerkleProof>`   | Inclusion paths and indices for signal verification              |
| `parameters`      | `Parameters`         | Risk thresholds and penalty factors                              |

### Output

| Name       | Type   | Description                                 |
| ---------- | ------ | ------------------------------------------- |
| `score`    | `u64`  | Composite performance score (0-1000+ range) |
| `verified` | `bool` | Boolean indicating Merkle proof validity    |

### Privacy Model

- **Private Inputs**: Individual trading signals (sensitive trading data)
- **Public Inputs**: Merkle paths, root, risk parameters (structural verification data)
- **Public Outputs**: Aggregated score and verification status

## Project Structure

```
circuits/
├── src/main.nr              # Main circuit implementation
├── Nargo.toml              # Noir project configuration
├── generate_inputs.py      # Test input generator
├── Prover.toml            # Generated test inputs (ignored by git)
└── target/                # Build artifacts (ignored by git)
```

## Contributing

1. Ensure all tests pass before submitting changes
2. Add safety comments to any `unsafe` blocks
3. Update test cases for new functionality
4. Maintain backward compatibility for input formats

## License

MIT

## Acknowledgments

Built with [Noir](https://noir-lang.org/) - A domain-specific language for zero-knowledge proofs.

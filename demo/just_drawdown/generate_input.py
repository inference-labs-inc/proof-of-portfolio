import toml
import numpy as np

ARRAY_SIZE = 365
SCALE = 10**18


def generate_inputs(n_returns: int):
    if n_returns > ARRAY_SIZE:
        raise ValueError(f"n_returns must be less than or equal to {ARRAY_SIZE}")

    log_returns = (np.random.randn(n_returns) * 0.01).tolist()

    # Scale up for fixed-point representation in Noir
    scaled_log_returns = [int(r * SCALE) for r in log_returns]

    # Pad with zeros
    padded_returns = scaled_log_returns + [0] * (ARRAY_SIZE - n_returns)

    # Create a dictionary for the Prover.toml file
    prover_toml = {
        "n_returns": n_returns,
        "log_returns": [str(r) for r in padded_returns],
    }

    # Write to Prover.toml
    with open("Prover.toml", "w") as f:
        toml.dump(prover_toml, f)

    # Also save the raw log returns for the baseline comparison
    np.save("log_returns.npy", np.array(log_returns))


if __name__ == "__main__":
    import argparse

    parser = argparse.ArgumentParser(
        description="Generate inputs for the drawdown circuit."
    )
    parser.add_argument(
        "--n_returns", type=int, default=30, help="Number of returns to generate."
    )
    args = parser.parse_args()

    generate_inputs(args.n_returns)

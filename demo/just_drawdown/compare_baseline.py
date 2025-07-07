import numpy as np
import math
import subprocess
import toml
from matplotlib import pyplot as plt

SCALE = 10**18
ARRAY_SIZE = 365


class MinMetrics:
    @staticmethod
    def daily_max_drawdown(log_returns: list[float]) -> float:
        if len(log_returns) == 0:
            return 0.0

        cumulative_log_returns = np.cumsum(log_returns)
        running_max_log = np.maximum.accumulate(cumulative_log_returns)
        drawdowns = 1 - np.exp(cumulative_log_returns - running_max_log)
        max_drawdown = np.max(drawdowns)

        return max_drawdown


def get_noir_output() -> float:

    result = subprocess.run(["nargo", "execute"], capture_output=True, text=True)

    if result.returncode != 0:
        print("Nargo execution failed:")
        print(result.stderr)
        raise RuntimeError("Nargo execution failed")

    try:

        output_line = [
            line
            for line in result.stdout.split("\\n")
            if "circuit output" in line.lower()
        ][0]

        output_value_str = output_line.split(":")[1].strip()

        if "(" in output_value_str:
            output_value_str = output_value_str.split("(")[1].split(")")[0]
        else:
            output_value_str = output_value_str.split("_")[0]

        if output_value_str.startswith("0x"):
            output_value = int(output_value_str, 16)
        else:
            output_value = int(output_value_str)

        if output_value >= 2**63:
            output_value -= 2**64

        return output_value / SCALE

    except (IndexError, ValueError) as e:
        print("Failed to parse Nargo output:")
        print(result.stdout)
        print(result.stderr)
        raise RuntimeError("Could not parse Nargo output") from e


def run_comparison():
    log_returns = np.load("log_returns.npy")
    baseline_max_drawdown = MinMetrics.daily_max_drawdown(log_returns.tolist())
    noir_max_drawdown = get_noir_output()

    print(f"Python baseline max drawdown: {baseline_max_drawdown}")
    print(f"Noir circuit max drawdown:    {noir_max_drawdown}")
    print(
        f"Difference:                   {abs(baseline_max_drawdown - noir_max_drawdown)}"
    )


def run_multi_comparison(n_runs=100):
    print(f"Running {n_runs} comparisons...")
    diffs = []
    python_results = []
    noir_results = []

    for i in range(n_runs):
        print(f"Run {i+1}/{n_runs}")
        n_returns = np.random.randint(30, ARRAY_SIZE)
        subprocess.run(
            ["python", "generate_input.py", "--n_returns", str(n_returns)], check=True
        )

        log_returns = np.load("log_returns.npy")

        baseline_res = MinMetrics.daily_max_drawdown(log_returns.tolist())
        noir_res = get_noir_output()

        python_results.append(baseline_res)
        noir_results.append(noir_res)
        diffs.append(abs(baseline_res - noir_res))

    print("\\n--- Comparison Results ---")
    print(f"Average Difference: {np.mean(diffs)}")
    print(f"Std Dev of Difference: {np.std(diffs)}")
    print(f"Max Difference: {np.max(diffs)}")

    plt.figure(figsize=(12, 6))
    plt.subplot(1, 2, 1)
    plt.plot(python_results, label="Python Baseline")
    plt.plot(noir_results, label="Noir Circuit")
    plt.title("Python vs Noir Results")
    plt.legend()

    plt.subplot(1, 2, 2)
    plt.plot(diffs, label="Difference (Abs)", color="red")
    plt.title("Absolute Difference")
    plt.legend()

    plt.suptitle("Max Drawdown Calculation Comparison")
    plt.tight_layout()
    plt.show()


if __name__ == "__main__":
    import argparse

    parser = argparse.ArgumentParser(
        description="Compare Python and Noir implementations of max drawdown."
    )
    parser.add_argument(
        "--multi",
        action="store_true",
        help="Run multiple comparisons and plot results.",
    )
    args = parser.parse_args()

    if args.multi:
        run_multi_comparison()
    else:
        subprocess.run(["python", "generate_input.py"], check=True)
        run_comparison()

from random import random
from typing import Union
import numpy as np
import math
import argparse
import subprocess
from matplotlib import pyplot as plt

SCALE = 10_000_000
WEIGHTED_AVERAGE_DECAY_RATE = 0.08
WEIGHTED_AVERAGE_DECAY_MIN = 0.40
WEIGHTED_AVERAGE_DECAY_MAX = 1.0
ANNUAL_RISK_FREE_PERCENTAGE = 4.19
DAYS_IN_YEAR = 365
ANNUAL_RISK_FREE_DECIMAL = ANNUAL_RISK_FREE_PERCENTAGE / 100
DAILY_LOG_RISK_FREE_RATE = math.log(1 + ANNUAL_RISK_FREE_DECIMAL) / DAYS_IN_YEAR
SHARPE_STDDEV_MINIMUM = 0.01  # ValiConfig.SHARPE_STDDEV_MINIMUM (1%)
STATISTICAL_CONFIDENCE_MINIMUM_N = 60  # ValiConfig.STATISTICAL_CONFIDENCE_MINIMUM_N
SHARPE_NOCONFIDENCE_VALUE = -100


class MinMetrics:
    @staticmethod
    def weighting_distribution(
        log_returns: Union[list[float], np.ndarray],
    ) -> np.ndarray:
        """
        Returns the weighting distribution that decays from max_weight to min_weight
        using the configured decay rate
        """
        max_weight = WEIGHTED_AVERAGE_DECAY_MAX
        min_weight = WEIGHTED_AVERAGE_DECAY_MIN
        decay_rate = WEIGHTED_AVERAGE_DECAY_RATE

        if len(log_returns) < 1:
            return np.ones(0)

        weighting_distribution_days = np.arange(0, len(log_returns))

        # Calculate decay from max to min
        weight_range = max_weight - min_weight
        decay_values = min_weight + (
            weight_range * np.exp(-decay_rate * weighting_distribution_days)
        )

        return decay_values[::-1][-len(log_returns) :]

    @staticmethod
    def average(
        log_returns: Union[list[float], np.ndarray],
        weighting=False,
        indices: Union[list[int], None] = None,
    ) -> float:
        """
        Returns the mean of the log returns
        """
        if len(log_returns) == 0:
            return 0.0

        weighting_distribution = MinMetrics.weighting_distribution(log_returns)

        if indices is not None and len(indices) != 0:
            indices = [i for i in indices if i in range(len(log_returns))]
            log_returns = [log_returns[i] for i in indices]
            weighting_distribution = [weighting_distribution[i] for i in indices]

        if weighting:
            avg_value = np.average(log_returns, weights=weighting_distribution)
        else:
            avg_value = np.mean(log_returns)

        return float(avg_value)

    @staticmethod
    def variance(
        log_returns: list[float],
        ddof: int = 1,
        weighting=False,
        indices: Union[list[int], None] = None,
    ) -> float:
        """
        Returns the standard deviation of the log returns
        """
        if len(log_returns) == 0:
            return 0.0

        window = len(indices) if indices is not None else len(log_returns)
        if window < ddof + 1:
            return np.inf

        return MinMetrics.average(
            (
                np.array(log_returns)
                - MinMetrics.average(log_returns, weighting=weighting, indices=indices)
            )
            ** 2,
            weighting=weighting,
            indices=indices,
        )

    @staticmethod
    def ann_volatility(
        log_returns: list[float],
        ddof: int = 1,
        weighting=False,
        indices: list[int] = None,
    ) -> float:
        """
        Calculates annualized volatility ASSUMING DAILY OBSERVATIONS
        Parameters:
        log_returns list[float]: Daily Series of log returns.
        ddof int: Delta Degrees of Freedom. The divisor used in the calculation is N - ddof, where N represents the number of elements.
        weighting bool: Whether to use weighted average.
        indices list[int]: The indices of the log returns to consider.
        """
        if indices is None:
            indices = list(range(len(log_returns)))

        # Annualize volatility of the daily log returns assuming sample variance
        days_in_year = DAYS_IN_YEAR

        window = len(indices)
        if window < ddof + 1:
            return np.inf

        annualized_volatility = np.sqrt(
            MinMetrics.variance(
                log_returns, ddof=ddof, weighting=weighting, indices=indices
            )
            * days_in_year
        )

        return float(annualized_volatility)

    @staticmethod
    def ann_excess_return(log_returns: list[float], weighting=False) -> float:
        """
        Calculates annualized excess return using mean daily log returns and mean daily 1yr risk free rate.
        Parameters:
        log_returns list[float]: Daily Series of log returns.
        """
        annual_risk_free_rate = ANNUAL_RISK_FREE_DECIMAL
        days_in_year = DAYS_IN_YEAR

        if len(log_returns) == 0:
            return 0.0

        # Annualize the mean daily excess returns
        annualized_excess_return = (
            MinMetrics.average(log_returns, weighting=weighting) * days_in_year
        ) - annual_risk_free_rate
        return annualized_excess_return

    @staticmethod
    def sharpe(
        log_returns: list[float],
        bypass_confidence: bool = False,
        weighting: bool = False,
        **kwargs,
    ) -> float:
        """
        Args:
            log_returns: list of daily log returns from the miner
            bypass_confidence: whether to use default value if not enough trading days
            weighting: whether to use weighted average
        """
        # Need a large enough sample size
        if len(log_returns) < STATISTICAL_CONFIDENCE_MINIMUM_N:
            if not bypass_confidence:
                return SHARPE_NOCONFIDENCE_VALUE

        # Hyperparameter
        min_std_dev = SHARPE_STDDEV_MINIMUM

        excess_return = MinMetrics.ann_excess_return(log_returns, weighting=weighting)
        volatility = MinMetrics.ann_volatility(log_returns, weighting=weighting)

        return float(excess_return / max(volatility, min_std_dev))


def __main__():
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--log-returns",
        type=float,
        nargs="+",
        default=[0.01, -0.02, 0.03, -0.01, 0.005],
        help="List of log returns to calculate Sharpe ratio",
    )
    parser.add_argument(
        "--bypass-confidence",
        action="store_true",
        help="Whether to bypass confidence check",
    )
    parser.add_argument(
        "--weighting", action="store_true", help="Whether to use weighted average"
    )
    args = parser.parse_args()

    print(
        MinMetrics.sharpe(
            log_returns=args.log_returns,
            bypass_confidence=args.bypass_confidence,
            weighting=args.weighting,
        )
    )
    run_nargo(args.log_returns, args.bypass_confidence, args.weighting)

    plt_results_nargo = []
    plt_results_baseline = []
    plt_diffs = []
    for i in range(100):
        log_returns = [np.random.normal(loc=0.001, scale=0.02) for _ in range(5)]
        fp = run_nargo(log_returns, args.bypass_confidence, args.weighting)
        plt_results_nargo.append(fp)
        plt_results_baseline.append(
            MinMetrics.sharpe(log_returns, args.bypass_confidence, args.weighting)
        )
        plt_diffs.append(
            abs(
                fp
                - MinMetrics.sharpe(log_returns, args.bypass_confidence, args.weighting)
            )
        )
    print("Avg diff", np.mean(plt_diffs))
    print("Std diff", np.std(plt_diffs))
    print("Max diff", np.max(plt_diffs))
    plt.plot(plt_results_nargo, label="Nargo")
    plt.plot(plt_results_baseline, label="Baseline")
    plt.plot(plt_diffs, label="Diff")
    plt.title(
        f"Circuit vs Baseline Sharpe Ratio (bypass_confidence: {args.bypass_confidence}, weighting: {args.weighting})"
    )
    plt.legend()
    plt.show()


def run_nargo(log_returns: list[float], bypass_confidence: bool, weighting: bool):
    with open("Prover.toml", "w") as f:
        f.write(f'actual_len = "{len(log_returns)}"\n')
        f.write(f'bypass_confidence = "{int(bypass_confidence)}"\n')
        scaled_returns = [str(int(lr * SCALE)) for lr in log_returns]
        f.write(f"daily_returns = {scaled_returns}\n")
        f.write(f'risk_free_rate = "{int(ANNUAL_RISK_FREE_DECIMAL * SCALE)}"\n')
        f.write(f'use_weighting = "{int(weighting)}"\n')
    result = subprocess.run(["nargo", "execute"], capture_output=True, text=True)
    fp = 0
    if "Field" in result.stdout:
        unsigned_i = int(result.stdout.split("Field(")[1].split(")")[0])

        if unsigned_i >= 2**63:
            i = unsigned_i - 2**64
        else:
            i = unsigned_i

        if i == SHARPE_NOCONFIDENCE_VALUE:
            fp = float(i)
        else:
            fp = i / SCALE
        print("---")
        print(fp)
        print(MinMetrics.sharpe(log_returns, bypass_confidence, weighting))
        print("Diff")
        print(fp - MinMetrics.sharpe(log_returns, bypass_confidence, weighting))
    if result.returncode != 0:
        print(result.stderr)
        raise RuntimeError("nargo execute failed")
    return fp


if __name__ == "__main__":
    __main__()

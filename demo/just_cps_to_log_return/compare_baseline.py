import json
import argparse
import subprocess
from datetime import datetime, timezone, date
from typing import Dict, List
import matplotlib.pyplot as plt
import numpy as np

SCALE = 10_000_000
DAILY_CHECKPOINTS = 2


class LedgerUtils:
    @staticmethod
    def daily_return_log_by_date(
        checkpoints: list, target_duration: int
    ) -> dict[date, float]:
        if not checkpoints:
            return {}

        daily_groups = {}
        n_checkpoints_per_day = DAILY_CHECKPOINTS

        for cp in checkpoints:
            start_time = cp["last_update_ms"] - cp["accum_ms"]
            full_cell = cp["accum_ms"] == target_duration

            running_date = datetime.fromtimestamp(
                start_time / 1000, tz=timezone.utc
            ).date()

            if full_cell:
                if running_date not in daily_groups:
                    daily_groups[running_date] = []
                daily_groups[running_date].append(cp)

        date_return_map = {}
        for running_date, day_checkpoints in sorted(daily_groups.items()):
            if len(day_checkpoints) == n_checkpoints_per_day:
                daily_return = sum(cp["gain"] + cp["loss"] for cp in day_checkpoints)
                date_return_map[running_date] = daily_return

        return date_return_map

    @staticmethod
    def daily_return_log(checkpoints: list, target_duration: int) -> list[float]:
        date_return_map = LedgerUtils.daily_return_log_by_date(
            checkpoints, target_duration
        )
        return list(date_return_map.values())


def load_validator_checkpoint_data(filepath: str = "../../validator_checkpoint.json"):
    try:
        with open(filepath, "r") as f:
            data = json.load(f)
        return data
    except FileNotFoundError:
        print(f"Validator checkpoint file not found at {filepath}")
        return None


def extract_test_data(
    validator_data: dict, miner_id: str = None, max_checkpoints: int = 200
):
    if not validator_data or "perf_ledgers" not in validator_data:
        print("No perf_ledgers found in validator data")
        return None

    perf_ledgers = validator_data["perf_ledgers"]

    if miner_id:
        if miner_id not in perf_ledgers:
            print(f"Miner {miner_id} not found in validator data")
            return None
        miner_data = perf_ledgers[miner_id]
    else:
        miner_ids = list(perf_ledgers.keys())
        if not miner_ids:
            print("No miners found in validator data")
            return None
        miner_id = miner_ids[0]
        miner_data = perf_ledgers[miner_id]
        print(f"Using first miner: {miner_id}")

    checkpoints = miner_data.get("cps", [])
    target_duration = miner_data.get("target_cp_duration_ms", 43200000)

    if not checkpoints:
        print(f"No checkpoints found for miner {miner_id}")
        return None

    test_checkpoints = checkpoints[:max_checkpoints]

    gains = [int(cp["gain"] * SCALE) for cp in test_checkpoints]
    losses = [int(cp["loss"] * SCALE) for cp in test_checkpoints]
    last_update_times = [cp["last_update_ms"] for cp in test_checkpoints]
    accum_times = [cp["accum_ms"] for cp in test_checkpoints]

    while len(gains) < max_checkpoints:
        gains.append(0)
        losses.append(0)
        last_update_times.append(0)
        accum_times.append(0)

    return {
        "gains": gains,
        "losses": losses,
        "last_update_times": last_update_times,
        "accum_times": accum_times,
        "checkpoint_count": len(test_checkpoints),
        "test_checkpoints": test_checkpoints,
        "target_duration": target_duration,
        "miner_id": miner_id,
    }


def run_nargo(
    gains: list,
    losses: list,
    last_update_times: list,
    accum_times: list,
    checkpoint_count: int,
    target_duration: int,
):
    with open("Prover.toml", "w") as f:
        f.write(f'checkpoint_count = "{checkpoint_count}"\n')
        f.write(f"gains = {gains}\n")
        f.write(f"losses = {losses}\n")
        f.write(f"last_update_times = {last_update_times}\n")
        f.write(f"accum_times = {accum_times}\n")
        f.write(f'target_duration = "{target_duration}"\n')

    result = subprocess.run(["nargo", "execute"], capture_output=True, text=True)

    if result.returncode != 0:
        print("Nargo execute failed:")
        print(result.stderr)
        raise RuntimeError("nargo execute failed")

    if "Circuit output:" in result.stdout:
        output_line = result.stdout.split("Circuit output: ")[1].strip()

        try:
            if output_line.startswith("Vec([Vec([") and output_line.endswith("])"):
                # Find the end of the inner Vec array
                inner_vec_end = output_line.rfind("]), Field(")
                if inner_vec_end != -1:
                    array_part = output_line[
                        10:inner_vec_end
                    ]  # Remove 'Vec([Vec([' at start
                    count_part = output_line[
                        inner_vec_end + 9 : -2
                    ]  # Get number after '), Field(' and before '])'

                    # Remove parentheses from count part if present
                    if count_part.startswith("(") and count_part.endswith(")"):
                        count_part = count_part[1:-1]

                    valid_days = int(count_part)

                    field_values = []
                    if array_part:
                        field_strings = array_part.split(", ")
                        for field_str in field_strings:
                            if field_str.startswith("Field(") and field_str.endswith(
                                ")"
                            ):
                                val = int(field_str[6:-1])
                                if val >= 2**63:
                                    val = val - 2**64
                                field_values.append(val / SCALE)
                            else:
                                field_values.append(0.0)

                    return field_values[:valid_days], valid_days
        except (ValueError, IndexError) as e:
            print(f"Error parsing circuit output: {e}")
            print(f"Raw output: {output_line}")

    return [], 0


def compare_implementations(test_data: dict):
    checkpoints = test_data["test_checkpoints"]
    target_duration = test_data["target_duration"]

    baseline_daily_returns = LedgerUtils.daily_return_log(checkpoints, target_duration)

    circuit_daily_returns, circuit_valid_days = run_nargo(
        test_data["gains"],
        test_data["losses"],
        test_data["last_update_times"],
        test_data["accum_times"],
        test_data["checkpoint_count"],
        target_duration,
    )

    baseline_count = len(baseline_daily_returns)

    print(f"Miner ID: {test_data['miner_id']}")
    print(f"Checkpoint count: {test_data['checkpoint_count']}")
    print(f"Target duration: {target_duration}")
    print(f"Baseline daily returns count: {baseline_count}")
    print(f"Circuit daily returns count: {circuit_valid_days}")

    if baseline_count > 0:
        print(
            f"Baseline daily returns: {baseline_daily_returns[:5]}{'...' if baseline_count > 5 else ''}"
        )
    if circuit_valid_days > 0:
        print(
            f"Circuit daily returns: {circuit_daily_returns[:5]}{'...' if circuit_valid_days > 5 else ''}"
        )

    if baseline_count == circuit_valid_days and baseline_count > 0:
        diffs = [
            abs(b - c) for b, c in zip(baseline_daily_returns, circuit_daily_returns)
        ]
        max_diff = max(diffs)
        avg_diff = sum(diffs) / len(diffs)
        print(f"Max difference: {max_diff}")
        print(f"Average difference: {avg_diff}")

        return {
            "baseline": baseline_daily_returns,
            "circuit": circuit_daily_returns,
            "max_diff": max_diff,
            "avg_diff": avg_diff,
            "count_match": True,
        }
    else:
        print(
            f"Count mismatch! Baseline: {baseline_count}, Circuit: {circuit_valid_days}"
        )
        return {
            "baseline": baseline_daily_returns,
            "circuit": circuit_daily_returns,
            "max_diff": float("inf"),
            "avg_diff": float("inf"),
            "count_match": False,
        }


def run_batch_test(validator_data: dict, num_tests: int = 10):
    perf_ledgers = validator_data.get("perf_ledgers", {})
    miner_ids = list(perf_ledgers.keys())
    results = []

    for i in range(min(num_tests, len(miner_ids))):
        miner_id = miner_ids[i]
        test_data = extract_test_data(validator_data, miner_id)

        if test_data:
            result = compare_implementations(test_data)
            results.append(result)
            print("---")

    if results:
        successful_results = [r for r in results if r["count_match"]]

        if successful_results:
            max_diffs = [r["max_diff"] for r in successful_results]
            avg_diffs = [r["avg_diff"] for r in successful_results]

            all_baseline_returns = []
            all_circuit_returns = []

            for r in successful_results:
                all_baseline_returns.extend(r["baseline"])
                all_circuit_returns.extend(r["circuit"])

            print(f"Batch test results ({len(successful_results)} successful tests):")
            print(f"Overall max difference: {max(max_diffs)}")
            print(f"Average max difference: {np.mean(max_diffs)}")
            print(f"Average avg difference: {np.mean(avg_diffs)}")
            print(f"Total daily returns compared: {len(all_baseline_returns)}")

            if len(all_baseline_returns) > 0:
                plt.figure(figsize=(15, 5))

                plt.subplot(1, 3, 1)
                plt.plot(all_baseline_returns[:100], "b-", label="Baseline", alpha=0.7)
                plt.plot(all_circuit_returns[:100], "r--", label="Circuit", alpha=0.7)
                plt.title("Baseline vs Circuit Returns (first 100)")
                plt.legend()

                plt.subplot(1, 3, 2)
                daily_diffs = [
                    abs(b - c)
                    for b, c in zip(all_baseline_returns, all_circuit_returns)
                ]
                plt.plot(daily_diffs[:100], "g-", alpha=0.7)
                plt.title("Daily Differences (first 100)")
                plt.ylabel("|Baseline - Circuit|")

                plt.subplot(1, 3, 3)
                plt.scatter(all_baseline_returns, all_circuit_returns, alpha=0.3, s=2)
                min_val = min(min(all_baseline_returns), min(all_circuit_returns))
                max_val = max(max(all_baseline_returns), max(all_circuit_returns))
                plt.plot([min_val, max_val], [min_val, max_val], "r--", alpha=0.8)
                plt.xlabel("Baseline")
                plt.ylabel("Circuit")
                plt.title("Circuit vs Baseline Scatter")

                plt.tight_layout()
                plt.show()
        else:
            print("No successful comparisons (all had count mismatches)")
    else:
        print("No results to analyze")


def main():
    parser = argparse.ArgumentParser(
        description="Compare Noir circuit with Python baseline for daily log returns"
    )
    parser.add_argument("--miner-id", type=str, help="Specific miner ID to test")
    parser.add_argument(
        "--batch-tests",
        type=int,
        default=10,
        help="Number of miners to test in batch mode",
    )
    parser.add_argument(
        "--max-checkpoints",
        type=int,
        default=200,
        help="Maximum checkpoints to test per miner",
    )

    args = parser.parse_args()

    validator_data = load_validator_checkpoint_data()

    if not validator_data:
        print("Failed to load validator data")
        return

    if args.miner_id:
        test_data = extract_test_data(
            validator_data, args.miner_id, args.max_checkpoints
        )
        if test_data:
            compare_implementations(test_data)
    else:
        run_batch_test(validator_data, args.batch_tests)


if __name__ == "__main__":
    main()

from random import random
import numpy as np
import math
import argparse
import subprocess
from matplotlib import pyplot as plt
from datetime import datetime, timezone

SCALE = 10000000
DAILY_CHECKPOINTS = 2
SECONDS_PER_DAY = 86400
TARGET_DURATION_MS = 43200000  # 12 hours in ms
MAX_CHECKPOINTS = 200


class PerfCheckpoint:
    def __init__(self, gain, loss, accum_ms, last_update_ms):
        self.gain = gain
        self.loss = loss
        self.accum_ms = accum_ms
        self.last_update_ms = last_update_ms


class PerfLedger:
    def __init__(self, cps):
        self.cps = cps


def daily_return_log(ledger):
    if ledger is None or not ledger.cps:
        return []
    date_return_map = daily_return_log_by_date(ledger)
    return list(date_return_map.values())


def daily_return_log_by_date(ledger):
    if not ledger.cps:
        return {}
    checkpoints = ledger.cps
    daily_groups = {}
    n_checkpoints_per_day = DAILY_CHECKPOINTS
    for cp in checkpoints:
        start_time = cp.last_update_ms - cp.accum_ms
        full_cell = cp.accum_ms == TARGET_DURATION_MS
        running_date = datetime.fromtimestamp(start_time / 1000, tz=timezone.utc).date()
        if full_cell:
            if running_date not in daily_groups:
                daily_groups[running_date] = []
            daily_groups[running_date].append(cp)
    date_return_map = {}
    for running_date, day_checkpoints in sorted(daily_groups.items()):
        if len(day_checkpoints) == n_checkpoints_per_day:
            daily_return = sum(cp.gain + cp.loss for cp in day_checkpoints)
            date_return_map[running_date] = daily_return
    return date_return_map


def generate_random_checkpoints(
    n_days,
    checkpoints_per_day=DAILY_CHECKPOINTS,
    target_duration=TARGET_DURATION_MS,
    max_checkpoints=MAX_CHECKPOINTS,
):
    cps = []
    scaled_gains = []
    scaled_losses = []
    last_updates = []
    accums = []
    base_time = 0
    day_ms = SECONDS_PER_DAY * 1000
    period_ms = target_duration
    count = 0
    for day in range(n_days):
        for cp_idx in range(checkpoints_per_day):
            if count >= max_checkpoints:
                break
            start_time = base_time + day * day_ms + cp_idx * period_ms
            last_update = start_time + period_ms
            accum = period_ms
            net = np.random.normal(0.001, 0.02)
            gain = max(net, 0)
            loss = min(net, 0)
            scaled_net = net * SCALE
            scaled_gain = int(max(scaled_net, 0))
            scaled_loss = int(min(scaled_net, 0))
            cps.append(PerfCheckpoint(gain, loss, accum, last_update))
            scaled_gains.append(scaled_gain)
            scaled_losses.append(scaled_loss)
            last_updates.append(last_update)
            accums.append(accum)
            count += 1
    padding = max_checkpoints - len(scaled_gains)
    scaled_gains += [0] * padding
    scaled_losses += [0] * padding
    last_updates += [0] * padding
    accums += [0] * padding
    return (
        cps,
        scaled_gains,
        scaled_losses,
        last_updates,
        accums,
        count,
        target_duration,
    )


def run_nargo(gains, losses, times, accums, count, target):
    with open("Prover.toml", "w") as f:
        f.write(f"gains = {gains}\n")
        f.write(f"losses = {losses}\n")
        f.write(f"last_update_times = {times}\n")
        f.write(f"accum_times = {accums}\n")
        f.write(f'checkpoint_count = "{count}"\n')
        f.write(f'target_duration = "{target}"\n')
    result = subprocess.run(["nargo", "execute"], capture_output=True, text=True)
    fp = 0.0
    if "Field" in result.stdout:
        unsigned_i = int(result.stdout.split("Field(")[1].split(")")[0])
        if unsigned_i >= 2**63:
            i = unsigned_i - 2**64
        else:
            i = unsigned_i
        fp = i / SCALE
        print("---")
        print("Nargo sum:", fp)
    if result.returncode != 0:
        print(result.stderr)
        raise RuntimeError("nargo execute failed")
    return fp


def __main__():
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--n_days", type=int, default=5, help="Number of days for random inputs"
    )
    args = parser.parse_args()
    cps, gains, losses, times, accums, count, target = generate_random_checkpoints(
        args.n_days
    )
    ledger = PerfLedger(cps)
    python_sum = sum(daily_return_log(ledger))
    print("Python sum:", python_sum)
    noir_sum = run_nargo(gains, losses, times, accums, count, target)
    print("Diff:", noir_sum - python_sum)
    plt_results_nargo = []
    plt_results_baseline = []
    plt_diffs = []
    for _ in range(100):
        cps, gains, losses, times, accums, count, target = generate_random_checkpoints(
            5
        )
        ledger = PerfLedger(cps)
        baseline = sum(daily_return_log(ledger))
        fp = run_nargo(gains, losses, times, accums, count, target)
        plt_results_nargo.append(fp)
        plt_results_baseline.append(baseline)
        plt_diffs.append(abs(fp - baseline))
    print("Avg diff", np.mean(plt_diffs))
    print("Std diff", np.std(plt_diffs))
    print("Max diff", np.max(plt_diffs))
    plt.plot(plt_results_nargo, label="Nargo")
    plt.plot(plt_results_baseline, label="Baseline")
    plt.plot(plt_diffs, label="Diff")
    plt.title("Circuit vs Baseline Sum of Daily Log Returns")
    plt.legend()
    plt.show()


if __name__ == "__main__":
    __main__()

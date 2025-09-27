#!/usr/bin/env python3
"""Test script for proof generation and verification with dummy data."""

import sys
from pathlib import Path
import traceback

project_root = Path(__file__).parent.parent.parent
sys.path.insert(0, str(project_root))
# ruff: noqa: E402
import proof_of_portfolio

ptn_path = project_root / "proprietary-trading-network"
sys.path.insert(0, str(ptn_path))
# ruff: noqa: E402
from vali_objects.vali_dataclasses.perf_ledger import PerfLedger, PerfCheckpoint
from vali_objects.utils.metrics import Metrics

SCALE = 100000000
MINER_HOTKEY = "5HTestMinerHotkey123456789abcdefghijklmnopqrstuv"
DAILY_RETURNS = [0.01, -0.005, 0.02, 0.015, -0.01, 0.005, 0.025, -0.002, 0.018, 0.008]
DAILY_PNL = [100.0, -50.0, 200.0, 150.0, -100.0, 50.0, 250.0, -20.0, 180.0, 80.0]
MINER_DATA = {
    "perf_ledgers": {
        MINER_HOTKEY: [
            {
                "cps": [
                    {
                        "timestamp": 1704067200.0,
                        "n_positions": 5,
                        "return_at_close": 0.02,
                        "mdd": 0.01,
                        "gain": 1000.0,
                        "loss": -500.0,
                        "net_flow": 500.0,
                        "market_open": 1704067200.0,
                        "market_close": 1704070800.0,
                        "prev_portfolio_ret": 0.015,
                    },
                    {
                        "timestamp": 1704153600.0,
                        "n_positions": 3,
                        "return_at_close": 0.015,
                        "mdd": 0.008,
                        "gain": 800.0,
                        "loss": -300.0,
                        "net_flow": 500.0,
                        "market_open": 1704153600.0,
                        "market_close": 1704157200.0,
                        "prev_portfolio_ret": 0.02,
                    },
                ]
            }
        ]
    },
    "daily_returns": DAILY_RETURNS,
    "positions": {
        MINER_HOTKEY: {
            "positions": [
                {
                    "position_uuid": "98765432-10ab-cdef-1234-567890abcdef",
                    "miner_hotkey": MINER_HOTKEY,
                    "position_type": "LONG",
                    "orders": [
                        {
                            "order_uuid": "12345678-90ab-cdef-1234-567890abcdef",
                            "trade_pair": "BTCUSD",
                            "processed_ms": 1704067200000,
                            "order_type": "MARKET",
                            "leverage": 1.0,
                            "order_status": "FILLED",
                            "price": 45000.0,
                            "quantity": 0.001,
                            "bid": 44990.0,
                            "ask": 45010.0,
                        }
                    ],
                    "net_volume": 0.001,
                    "average_entry_price": 45000.0,
                    "close_out_type": "TIME_BASED",
                    "return_at_close": 0.02,
                }
            ]
        }
    },
}


def create_perf_ledger():
    """Create a proper PerfLedger from test data."""

    checkpoints = []
    cumulative_return = 1.0
    max_return = 1.0

    for i, daily_ret in enumerate(DAILY_RETURNS):
        cumulative_return *= 1 + daily_ret
        max_return = max(max_return, cumulative_return)
        mdd = (max_return - cumulative_return) / max_return if max_return > 0 else 0.0

        checkpoint = PerfCheckpoint(
            last_update_ms=int((1704067200.0 + i * 86400) * 1000),
            prev_portfolio_ret=DAILY_RETURNS[i - 1] if i > 0 else 0.0,
            prev_portfolio_spread_fee=1.0,
            prev_portfolio_carry_fee=1.0,
            accum_ms=0,
            open_ms=int((1704067200.0 + i * 86400) * 1000),
            n_updates=1,
            gain=max(0, DAILY_PNL[i]),
            loss=min(0, DAILY_PNL[i]),
            spread_fee_loss=0.0,
            carry_fee_loss=0.0,
            mdd=mdd,
            mpv=cumulative_return,
            pnl_gain=max(0, DAILY_PNL[i]),
            pnl_loss=min(0, DAILY_PNL[i]),
        )
        checkpoints.append(checkpoint)

    perf_ledger = PerfLedger(cps=checkpoints)
    return perf_ledger


def calculate_ptn_metrics():
    """Calculate metrics using PTN's functions as source of truth."""

    circuit_daily_returns = DAILY_RETURNS

    perf_ledger = create_perf_ledger()

    sharpe = Metrics.sharpe(
        log_returns=circuit_daily_returns,
        bypass_confidence=True,
        weighting=False,
        days_in_year=365,
    )

    sortino = Metrics.sortino(
        log_returns=circuit_daily_returns,
        bypass_confidence=True,
        weighting=False,
        days_in_year=365,
    )

    calmar = Metrics.calmar(
        log_returns=circuit_daily_returns,
        ledger=perf_ledger,
        bypass_confidence=True,
        weighting=False,
        days_in_year=365,
    )

    omega = Metrics.omega(
        log_returns=circuit_daily_returns, bypass_confidence=True, weighting=False
    )

    return {
        "sharpe": sharpe,
        "sortino": sortino,
        "calmar": calmar,
        "omega": omega,
        "ptn_daily_returns": circuit_daily_returns,
    }


def generate_proof():
    """Generate proof with test data."""

    ptn_results = calculate_ptn_metrics()
    augmented_scores = {
        k: v for k, v in ptn_results.items() if k != "ptn_daily_returns"
    }

    return proof_of_portfolio.prove_sync(
        miner_data=MINER_DATA,
        daily_pnl=DAILY_PNL,
        hotkey=MINER_HOTKEY,
        verbose=True,
        use_weighting=False,
        bypass_confidence=True,
        witness_only=False,
        augmented_scores=augmented_scores,
    )


def verify_proof(proof_hex: str, public_inputs_hex: str) -> bool:
    """Verify generated proof."""
    return proof_of_portfolio.verify(proof_hex, public_inputs_hex)


def load_proof_files(proof_dir: Path) -> tuple[str, str]:
    """Load proof and public inputs from files."""
    proof_path = proof_dir / "proof"
    public_inputs_path = proof_dir / "public_inputs"

    if not (proof_path.exists() and public_inputs_path.exists()):
        raise FileNotFoundError("Proof files not found")

    with open(proof_path, "rb") as f:
        proof_hex = f.read().hex()

    with open(public_inputs_path, "rb") as f:
        public_inputs_hex = f.read().hex()

    return proof_hex, public_inputs_hex


def main() -> int:
    """Run proof generation and verification test."""
    try:
        result = generate_proof()

        if result.get("status") != "success":
            return 1

        proof_results = result.get("proof_results", {})
        if not proof_results.get("proof_generated"):
            return 1

        proof_dir = project_root / "proof_of_portfolio" / "circuits" / "proof"
        proof_hex, public_inputs_hex = load_proof_files(proof_dir)

        if verify_proof(proof_hex, public_inputs_hex):
            return 0
        else:
            return 1

    except FileNotFoundError:
        return 1
    except Exception:
        traceback.print_exc()
        return 1


if __name__ == "__main__":
    sys.exit(main())

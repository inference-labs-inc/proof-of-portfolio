#!/usr/bin/env python3
"""Test script for proof generation and verification with dummy data."""

import sys
from pathlib import Path

project_root = Path(__file__).parent.parent.parent
sys.path.insert(0, str(project_root))

# ruff: noqa: E402
import proof_of_portfolio

MINER_HOTKEY = "5HTestMinerHotkey123456789abcdefghijklmnopqrstuv"

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
    "daily_returns": [0.01 * (1 + i % 3 - 1) for i in range(30)],
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

DAILY_PNL = [0.01, -0.005, 0.02, 0.015, -0.01, 0.005, 0.025, -0.002, 0.018, 0.008]


def generate_proof():
    """Generate proof with test data."""
    return proof_of_portfolio.prove_sync(
        miner_data=MINER_DATA,
        daily_pnl=DAILY_PNL,
        hotkey=MINER_HOTKEY,
        verbose=False,
        use_weighting=False,
        bypass_confidence=True,
        witness_only=False,
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
            print(f"✗ Prove function failed: {result.get('message', 'unknown error')}")
            return 1

        print("✓ Prove function executed successfully")

        proof_results = result.get("proof_results", {})
        if not proof_results.get("proof_generated"):
            print("✗ No proof was generated")
            return 1

        print("✓ Proof was generated successfully")

        proof_dir = project_root / "proof_of_portfolio" / "circuits" / "proof"
        proof_hex, public_inputs_hex = load_proof_files(proof_dir)

        if verify_proof(proof_hex, public_inputs_hex):
            print("✓ Proof verification successful")
            return 0
        else:
            print("✗ Proof verification failed")
            return 1

    except FileNotFoundError as e:
        print(f"✗ {e}")
        return 1
    except Exception as e:
        print(f"✗ Exception during test: {e}")
        import traceback

        traceback.print_exc()
        return 1


if __name__ == "__main__":
    sys.exit(main())

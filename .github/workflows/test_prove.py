#!/usr/bin/env python3
"""Test script for the prove function with dummy data."""

import sys
import os
import hashlib
import shutil
import traceback

# Add the project root to Python path to use local development version
project_root = os.path.abspath(os.path.join(os.path.dirname(__file__), "../.."))
sys.path.insert(0, project_root)

# ruff: noqa: E402
import proof_of_portfolio
import proof_of_portfolio.verifier as verifier_module

miner_hotkey = "5HTestMinerHotkey123456789abcdefghijklmnopqrstuv"


miner_data = {
    "perf_ledgers": {
        miner_hotkey: [
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
        miner_hotkey: {
            "positions": [
                {
                    "position_uuid": "98765432-10ab-cdef-1234-567890abcdef",
                    "miner_hotkey": miner_hotkey,
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


def get_file_hash(path):
    if os.path.exists(path):
        with open(path, "rb") as f:
            return hashlib.sha256(f.read()).hexdigest()
    return "NOT_FOUND"


daily_pnl = [0.01, -0.005, 0.02, 0.015, -0.01, 0.005, 0.025, -0.002, 0.018, 0.008]


try:
    result = proof_of_portfolio.prove_sync(
        miner_data=miner_data,
        daily_pnl=daily_pnl,
        hotkey=miner_hotkey,
        verbose=True,
        use_weighting=False,
        bypass_confidence=True,
        witness_only=False,
    )

    bb_path = shutil.which("bb") or os.path.expanduser("~/.bb/bb")
    nargo_path = shutil.which("nargo") or os.path.expanduser("~/.nargo/bin/nargo")

    # Check CRS hash for comparison with local
    crs_path = os.path.expanduser("~/.bb-crs/bn254_g1.dat")
    if os.path.exists(crs_path):
        crs_hash = get_file_hash(crs_path)
        crs_size = os.path.getsize(crs_path)
        print(f"CRS bn254_g1.dat hash: {crs_hash}, size: {crs_size} bytes")
    else:
        print("CRS bn254_g1.dat not found")

    # Check circuit bytecode hash
    circuit_hash = get_file_hash("proof_of_portfolio/circuits/target/circuits.json")
    print(f"Circuit bytecode hash: {circuit_hash}")

    if result.get("status") == "success":
        print("✓ Prove function executed successfully")
        print(f"Portfolio metrics: {result.get('portfolio_metrics', {})}")

        proof_results = result.get("proof_results", {})
        if proof_results.get("proof_generated"):
            print("✓ Proof was generated successfully")

            try:
                proof_path = os.path.join("proof_of_portfolio/circuits/proof", "proof")
                public_inputs_path = os.path.join(
                    "proof_of_portfolio/circuits/proof", "public_inputs"
                )

                if os.path.exists(proof_path) and os.path.exists(public_inputs_path):
                    with open(proof_path, "rb") as f:
                        proof_hex = f.read().hex()

                    with open(public_inputs_path, "rb") as f:
                        public_inputs_hex = f.read().hex()

                    vk_path = os.path.join(
                        os.path.dirname(verifier_module.__file__),
                        "circuits",
                        "vk",
                        "vk",
                    )
                    if os.path.exists(vk_path):
                        vk_hash = hashlib.sha256(open(vk_path, "rb").read()).hexdigest()
                        vk_size = os.path.getsize(vk_path)
                        print(
                            f"VK file found at {vk_path}, size: {vk_size} bytes, hash: {vk_hash}"
                        )
                    else:
                        print(f"VK file NOT found at {vk_path}")

                    # Verify the proof using hex data
                    verification_result = proof_of_portfolio.verify(
                        proof_hex, public_inputs_hex
                    )

                    if verification_result:
                        print("✓ Proof verification successful")
                    else:
                        print("✗ CRITICAL: Proof verification failed")
                else:
                    print("✗ Proof files not found at expected paths")
                    print(f"  Expected: {proof_path}")
                    print(f"  Expected: {public_inputs_path}")
                    exit(1)

            except Exception as ve:
                print(f"✗ Proof verification exception: {str(ve)}")
                exit(1)
        else:
            print("✗ No proof was generated")
            exit(1)
    elif result.get("status") == "error":
        print(f"✗ Prove function failed: {result.get('message', 'unknown error')}")
        exit(1)
    else:
        print(f"⚠ Prove function returned unexpected status: {result.get('status')}")

except Exception as e:
    print(f"✗ Exception during prove function: {str(e)}")

    traceback.print_exc()
    exit(1)

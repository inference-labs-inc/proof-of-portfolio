#!/usr/bin/env python3
"""Test script for the prove function with dummy data."""

import os


import proof_of_portfolio


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

print(f"Testing prove function with miner: {miner_hotkey}")
print(
    f"Data contains {len(miner_data['perf_ledgers'][miner_hotkey])} perf_ledgers and {len(miner_data['positions'][miner_hotkey]['positions'])} positions"
)


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

    print(f"Prove function completed with status: {result.get('status', 'unknown')}")

    if result.get("status") == "success":
        print("✓ Prove function executed successfully")
        print(f"Portfolio metrics: {result.get('portfolio_metrics', {})}")

        proof_results = result.get("proof_results", {})
        if proof_results.get("proof_generated"):
            print("✓ Proof was generated successfully")

            try:
                import os

                proof_path = os.path.join("proof_of_portfolio/circuits/proof", "proof")
                public_inputs_path = os.path.join(
                    "proof_of_portfolio/circuits/proof", "public_inputs"
                )

                if os.path.exists(proof_path) and os.path.exists(public_inputs_path):
                    with open(proof_path, "rb") as f:
                        proof_hex = f.read().hex()

                    with open(public_inputs_path, "rb") as f:
                        public_inputs_hex = f.read().hex()

                    # Check verification key file
                    import proof_of_portfolio.verifier as verifier_module

                    vk_path = os.path.join(
                        os.path.dirname(verifier_module.__file__),
                        "circuits",
                        "vk",
                        "vk",
                    )
                    if os.path.exists(vk_path):
                        vk_size = os.path.getsize(vk_path)
                        print(f"VK file found at {vk_path}, size: {vk_size} bytes")
                    else:
                        print(f"VK file NOT found at {vk_path}")

                    # Check VK content hash to ensure it matches
                    import hashlib

                    with open(vk_path, "rb") as f:
                        vk_hash = hashlib.sha256(f.read()).hexdigest()
                    print(f"VK SHA256: {vk_hash}")

                    # Check bb version
                    import subprocess

                    bb_path = os.path.expanduser("~/.bb/bb")
                    if os.path.exists(bb_path):
                        result = subprocess.run(
                            [bb_path, "--version"], capture_output=True, text=True
                        )
                        print(f"BB version: {result.stdout.strip()}")

                    # Try direct bb verify command for comparison
                    print("Testing direct bb verification...")
                    try:
                        result = subprocess.run(
                            [
                                bb_path,
                                "verify",
                                "-k",
                                vk_path,
                                "-p",
                                proof_path,
                                "-i",
                                public_inputs_path,
                            ],
                            capture_output=True,
                            text=True,
                        )
                        print(f"Direct bb verify result: {result.returncode}")
                        if result.returncode != 0:
                            print(f"Direct bb verify stderr: {result.stderr}")
                    except Exception as e:
                        print(f"Direct bb verify failed: {e}")

                    # Verify the proof using hex data
                    verification_result = proof_of_portfolio.verify(
                        proof_hex, public_inputs_hex
                    )

                    if verification_result:
                        print("✓ Proof verification successful")
                    else:
                        print("✗ Proof verification failed")
                        exit(1)
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
    import traceback

    traceback.print_exc()
    exit(1)

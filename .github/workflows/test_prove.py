#!/usr/bin/env python3
"""Test script for the prove function with dummy data."""

import proof_of_portfolio

# Create test data with correct structure
miner_hotkey = "5HTestMinerHotkey123456789"

# The data structure expected by prove_sync
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
    "positions": {
        miner_hotkey: {
            "positions": [
                {
                    "position_uuid": "test-position-1",
                    "miner_hotkey": miner_hotkey,
                    "position_type": "LONG",
                    "orders": [
                        {
                            "order_uuid": "test-order-1",
                            "trade_pair": "BTCUSD",
                            "processed_ms": 1704067200000,
                            "order_type": "MARKET",
                            "leverage": 1.0,
                            "order_status": "FILLED",
                            "price": 45000.0,
                            "quantity": 0.001,
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

# Create dummy daily PnL data (required parameter)
daily_pnl = [0.01, -0.005, 0.02, 0.015, -0.01, 0.005, 0.025, -0.002, 0.018, 0.008]

# Test the prove function
try:
    result = proof_of_portfolio.prove_sync(
        miner_data=miner_data,
        daily_pnl=daily_pnl,
        hotkey=miner_hotkey,
        verbose=True,
        witness_only=True,  # Only generate witness, not full proof for speed
    )

    print(f"Prove function completed with status: {result.get('status', 'unknown')}")

    if result.get("status") == "success":
        print("✓ Prove function executed successfully")
        print(f"Portfolio metrics: {result.get('portfolio_metrics', {})}")
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

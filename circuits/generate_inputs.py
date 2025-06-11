#!/usr/bin/env python3

COMPUTED_MERKLE_ROOT = (
    "11867626551045947428625699719016106318414315494538029175888081011781332338787"
)

toml_content = f"""# Generated test inputs for miner scoring circuit

# Circuit parameters
n_signals = "1"
merkle_root = "{COMPUTED_MERKLE_ROOT}"
max_drawdown = "300"
risk_profile_penalty = "1000"

# Merkle proof paths (all zeros for single-leaf tree)
path_elements = [
    ["0", "0", "0", "0"],
    ["0", "0", "0", "0"],
    ["0", "0", "0", "0"],
    ["0", "0", "0", "0"],
    ["0", "0", "0", "0"],
    ["0", "0", "0", "0"],
    ["0", "0", "0", "0"],
    ["0", "0", "0", "0"],
]

path_indices = [
    ["0", "0", "0", "0"],
    ["0", "0", "0", "0"],
    ["0", "0", "0", "0"],
    ["0", "0", "0", "0"],
    ["0", "0", "0", "0"],
    ["0", "0", "0", "0"],
    ["0", "0", "0", "0"],
    ["0", "0", "0", "0"],
]

# Trading signals (first signal is real, rest are padding)
[[signals]]
miner_hotkey = ["1", "2"]
trade_pair_id = "1"
order_type = "1"
leverage_scaled = "2"
price_scaled = "100000"
processed_ms = "1234567890"
order_uuid = ["1", "1"]
position_uuid = ["1", "1"]
src = "1"

[[signals]]
miner_hotkey = ["0", "0"]
trade_pair_id = "0"
order_type = "0"
leverage_scaled = "0"
price_scaled = "0"
processed_ms = "0"
order_uuid = ["0", "0"]
position_uuid = ["0", "0"]
src = "0"

[[signals]]
miner_hotkey = ["0", "0"]
trade_pair_id = "0"
order_type = "0"
leverage_scaled = "0"
price_scaled = "0"
processed_ms = "0"
order_uuid = ["0", "0"]
position_uuid = ["0", "0"]
src = "0"

[[signals]]
miner_hotkey = ["0", "0"]
trade_pair_id = "0"
order_type = "0"
leverage_scaled = "0"
price_scaled = "0"
processed_ms = "0"
order_uuid = ["0", "0"]
position_uuid = ["0", "0"]
src = "0"

[[signals]]
miner_hotkey = ["0", "0"]
trade_pair_id = "0"
order_type = "0"
leverage_scaled = "0"
price_scaled = "0"
processed_ms = "0"
order_uuid = ["0", "0"]
position_uuid = ["0", "0"]
src = "0"

[[signals]]
miner_hotkey = ["0", "0"]
trade_pair_id = "0"
order_type = "0"
leverage_scaled = "0"
price_scaled = "0"
processed_ms = "0"
order_uuid = ["0", "0"]
position_uuid = ["0", "0"]
src = "0"

[[signals]]
miner_hotkey = ["0", "0"]
trade_pair_id = "0"
order_type = "0"
leverage_scaled = "0"
price_scaled = "0"
processed_ms = "0"
order_uuid = ["0", "0"]
position_uuid = ["0", "0"]
src = "0"

[[signals]]
miner_hotkey = ["0", "0"]
trade_pair_id = "0"
order_type = "0"
leverage_scaled = "0"
price_scaled = "0"
processed_ms = "0"
order_uuid = ["0", "0"]
position_uuid = ["0", "0"]
src = "0"
"""

with open("Prover.toml", "w") as f:
    f.write(toml_content)

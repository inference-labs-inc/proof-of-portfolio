import json
import os
import sys
from pathlib import Path
import subprocess
import toml
import re
import gzip

class Miner:
    def __init__(self, ss58_address, name):
        self.name = name
        self.ss58_address = ss58_address
        self.TREE_GEN_DIR = "../tree_generator"
        self.TREE_GEN_PROVER_TOML = os.path.join(self.TREE_GEN_DIR, "Prover.toml")
        self.MAX_SIGNALS = 256

    def prepare_signals_from_data(self, data_json_path):
        """
        Reads the data.json file for a hotkey, extracts all their orders,
        and transforms them into a list of TradingSignal dicts for the circuits.

        Args:
            data_json_path (str): Path to the data.json file

        Returns:
            tuple: (padded_signals, actual_len)
        """
        print(f"Preparing signals from {data_json_path}...")
        try:
            with open(data_json_path, "r") as f:
                positions = json.load(f)
        except FileNotFoundError:
            print(f"ERROR: Data file not found at {data_json_path}")
            return None, 0
        except json.JSONDecodeError:
            print(f"ERROR: Could not decode JSON from {data_json_path}")
            return None, 0

        if not positions:
            print(f"Warning: No positions found in {data_json_path}")
            return [], 0

        orders = []
        for position in positions:
            orders.extend(position.get("orders", []))

        # Sort orders by timestamp to ensure correct open/close pairing
        orders.sort(key=lambda o: o["processed_ms"])

        signals = []

        # Assumes orders come in pairs (open, close).
        for i in range(0, len(orders), 2):
            if (i + 1) >= len(orders) or len(signals) >= self.MAX_SIGNALS:
                break

            open_order = orders[i]
            close_order = orders[i + 1]

            # Map string order types to numeric codes for the circuit
            # LONG -> 1 (Open Long), SHORT -> 3 (Open Short), FLAT -> 2/4 (Close)
            if open_order["order_type"] == "LONG":
                open_order_type = "1"  # Open Long
                close_order_type = "2"  # Close Long
            elif open_order["order_type"] == "SHORT":
                open_order_type = "3"  # Open Short
                close_order_type = "4"  # Close Short
            else:
                # Fallback to leverage-based detection
                is_long = open_order["leverage"] > 0
                open_order_type = "1" if is_long else "3"
                close_order_type = "2" if is_long else "4"

            # Convert UUIDs to two Fields. We split the hex string in half.
            open_uuid_hex = open_order["order_uuid"].replace("-", "")
            close_uuid_hex = close_order["order_uuid"].replace("-", "")

            # Position UUID should be the same for the pair, use the first one.
            pos_uuid_hex = open_order["order_uuid"].replace("-", "")

            # Create open signal
            signals.append(
                {
                    "miner_hotkey": ["0", "0"],
                    "trade_pair_id": "0",
                    "order_type": open_order_type,
                    "leverage_scaled": str(
                        int(abs(open_order["leverage"]) * 100)  # SCALING_FACTOR = 100
                    ),
                    "price_scaled": str(int(open_order["price"] * 100)),  # SCALING_FACTOR = 100
                    "processed_ms": str(open_order["processed_ms"]),
                    "order_uuid": [f"0x{open_uuid_hex[:16]}", f"0x{open_uuid_hex[16:]}"],
                    "position_uuid": [f"0x{pos_uuid_hex[:16]}", f"0x{pos_uuid_hex[16:]}"],
                    "src": str(open_order["src"]),
                }
            )

            # Create close signal
            signals.append(
                {
                    "miner_hotkey": ["0", "0"],
                    "trade_pair_id": "0",
                    "order_type": close_order_type,
                    "leverage_scaled": str(
                        int(abs(open_order["leverage"]) * 100)  # SCALING_FACTOR = 100
                    ),  # Leverage is same for the pair
                    "price_scaled": str(int(close_order["price"] * 100)),  # SCALING_FACTOR = 100
                    "processed_ms": str(close_order["processed_ms"]),
                    "order_uuid": [f"0x{close_uuid_hex[:16]}", f"0x{close_uuid_hex[16:]}"],
                    "position_uuid": [f"0x{pos_uuid_hex[:16]}", f"0x{pos_uuid_hex[16:]}"],
                    "src": str(close_order["src"]),
                }
            )

        actual_len = len(signals)
        if actual_len == 0:
            print(f"Warning: No valid order pairs found in {data_json_path}")
            return [], 0

        # Pad signals if we have fewer than MAX_SIGNALS
        padded_signals = signals + [
            {
                "miner_hotkey": ["0", "0"],
                "trade_pair_id": "0",
                "order_type": "0",
                "leverage_scaled": "0",
                "price_scaled": "0",
                "processed_ms": "0",
                "order_uuid": ["0", "0"],
                "position_uuid": ["0", "0"],
                "src": "0",
            }
        ] * (self.MAX_SIGNALS - actual_len)

        print(f"Successfully prepared {actual_len} signals.")
        return padded_signals, actual_len

    def run_merkle_generator(self, signals, actual_len):
        """
        Runs the merkle_generator circuit and parses the witness file to get the output.

        Args:
            signals (list): List of trading signals
            actual_len (int): Actual number of signals

        Returns:
            tuple: (merkle_root, path_elements, path_indices) or None if failed
        """
        print("Running Merkle Generator circuit...")

        merkle_input = {"signals": signals, "actual_len": actual_len}

        witness_name = "merkle_witness"
        witness_path = os.path.join(self.TREE_GEN_DIR, "target", f"{witness_name}.gz")

        with open(self.TREE_GEN_PROVER_TOML, "w") as f:
            toml.dump(merkle_input, f)

        # Find nargo executable
        nargo_cmd = "nargo"
        # Common locations for nargo
        nargo_paths = [
            os.path.expanduser("~/.nargo/bin/nargo"),
            os.path.expanduser("~/.noir/bin/nargo"),
            os.path.expanduser("~/.cargo/bin/nargo"),
            os.path.expanduser("~/.noirup/bin/nargo")
        ]

        # Check if nargo exists in common locations
        for path in nargo_paths:
            if os.path.isfile(path) and os.access(path, os.X_OK):
                nargo_cmd = path
                print(f"Found nargo at: {nargo_cmd}")
                break

        print("Executing nargo... (This might take a moment)")
        result = subprocess.run(
            [nargo_cmd, "execute", witness_name, "--silence-warnings"],
            cwd=self.TREE_GEN_DIR,
            capture_output=True,
            text=True,
        )

        if result.returncode != 0:
            print("Merkle generator execution failed!")
            print(result.stderr)
            return None

        print(f"Merkle generator executed successfully. Witness saved to {witness_path}")

        try:
            output_str = result.stdout

            def parse_array_from_output(array_name, s):
                pattern = re.compile(rf'"{array_name}": Vec\((.*?)\), "', re.DOTALL)
                match = pattern.search(s)
                if not match:
                    raise ValueError(f"Could not find {array_name} in output")

                array_content = match.group(1)

                field_strs = re.findall(r"Field\(([^)]+)\)", array_content)

                PRIME = 21888242871839275222246405745257275088548364400416034343698204186575808495617
                values = []
                for field_str in field_strs:
                    val = int(field_str)
                    if val < 0:
                        val = PRIME + val  # Convert negative to positive field element
                    values.append(str(val))
                return values

            root_match = re.search(r'"root": Field\(([^)]+)\)', output_str)
            if not root_match:
                raise ValueError("Could not parse Merkle root from output.")

            PRIME = 21888242871839275222246405745257275088548364400416034343698204186575808495617
            root_val = int(root_match.group(1))
            if root_val < 0:
                root_val = PRIME + root_val
            merkle_root = str(root_val)

            path_elements_flat = parse_array_from_output("path_elements", output_str)
            path_indices_flat = parse_array_from_output("path_indices", output_str)

            merkle_depth = 8

            path_elements = [
                path_elements_flat[i : i + merkle_depth]
                for i in range(0, len(path_elements_flat), merkle_depth)
            ]
            path_indices = [
                path_indices_flat[i : i + merkle_depth]
                for i in range(0, len(path_indices_flat), merkle_depth)
            ]

            print("Successfully parsed Merkle tree data from circuit output.")
            return merkle_root, path_elements, path_indices

        except Exception as e:
            print(f"Failed to parse Merkle generator output: {e}")
            print("Raw output:", result.stdout)
            return None

    def generate_tree(self, input_json_path: str):
        """
        Generates a Merkle tree from a child hotkey data.json file and saves it to the child's subdirectory.

        Args:
            input_json_path (str): Path to the child hotkey data.json file

        Returns:
            dict: Tree data containing merkle_root, path_elements, and path_indices, or None if failed
        """
        # Prepare signals from the data.json file
        signals, actual_len = self.prepare_signals_from_data(input_json_path)
        if not signals or actual_len == 0:
            print("Could not prepare signals. Exiting.")
            return None

        # Run Merkle Generator
        merkle_data = self.run_merkle_generator(signals, actual_len)
        if not merkle_data:
            print("Halting due to error in Merkle generation.")
            return None

        merkle_root, path_elements, path_indices = merkle_data

        # Create tree data dictionary
        tree_data = {
            "merkle_root": merkle_root,
            "path_elements": path_elements,
            "path_indices": path_indices,
            "actual_len": actual_len
        }

        # Save tree data to the child's subdirectory
        output_dir = os.path.dirname(input_json_path)
        tree_file = os.path.join(output_dir, "tree.json")

        try:
            with open(tree_file, 'w') as f:
                json.dump(tree_data, f, indent=2)
            print(f"Tree data saved to {tree_file}")
        except Exception as e:
            print(f"Error saving tree data: {e}")
            return None

        # Clean up temporary files
        if os.path.exists(self.TREE_GEN_PROVER_TOML):
            os.remove(self.TREE_GEN_PROVER_TOML)

        merkle_witness_path = os.path.join(self.TREE_GEN_DIR, "target", "merkle_witness.gz")
        if os.path.exists(merkle_witness_path):
            os.remove(merkle_witness_path)

        return tree_data

    def __str__(self):
        return self.name

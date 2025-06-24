import json
import subprocess
import toml
import re
import os
import gzip

CHECKPOINT_FILE = "validator_checkpoint.json"
CIRCUITS_DIR = "circuits"
TREE_GEN_DIR = "tree_generator"
MAIN_PROVER_TOML = os.path.join(CIRCUITS_DIR, "Prover.toml")
TREE_GEN_PROVER_TOML = os.path.join(TREE_GEN_DIR, "Prover.toml")

TARGET_HOTKEY = "5C5W8HYYUMgQKZhpPdZgjfJXt1GK2aBm7K3WAbX25P2JgMYJ"
MAX_SIGNALS = 256
SCALING_FACTOR = 10**2
RISK_FREE_RATE_ANNUAL_PERCENT = 4.19


def prepare_signals_from_checkpoint(checkpoint_file, hotkey):
    """
    Reads the validator checkpoint, finds the specified hotkey, extracts all their orders,
    and transforms them into a list of TradingSignal dicts for the circuits.
    """
    print(f"Step 1: Preparing signals for hotkey {hotkey} from {checkpoint_file}...")
    try:
        with open(checkpoint_file, "r") as f:
            checkpoint_data = json.load(f)
    except FileNotFoundError:
        print(f"ERROR: Checkpoint file not found at {checkpoint_file}")
        return None, 0
    except json.JSONDecodeError:
        print(f"ERROR: Could not decode JSON from {checkpoint_file}")
        return None, 0

    miner_positions = (
        checkpoint_data.get("positions", {}).get(hotkey, {}).get("positions", [])
    )
    if not miner_positions:
        print(f"Warning: No positions found for hotkey {hotkey}")
        return [], 0

    orders = []
    for position in miner_positions:
        orders.extend(position.get("orders", []))

    # Sort orders by timestamp to ensure correct open/close pairing
    orders.sort(key=lambda o: o["processed_ms"])

    signals = []

    # Assumes orders come in pairs (open, close).
    for i in range(0, len(orders), 2):
        if (i + 1) >= len(orders) or len(signals) >= MAX_SIGNALS:
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
                    int(abs(open_order["leverage"]) * SCALING_FACTOR)
                ),
                "price_scaled": str(int(open_order["price"] * SCALING_FACTOR)),
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
                    int(abs(open_order["leverage"]) * SCALING_FACTOR)
                ),  # Leverage is same for the pair
                "price_scaled": str(int(close_order["price"] * SCALING_FACTOR)),
                "processed_ms": str(close_order["processed_ms"]),
                "order_uuid": [f"0x{close_uuid_hex[:16]}", f"0x{close_uuid_hex[16:]}"],
                "position_uuid": [f"0x{pos_uuid_hex[:16]}", f"0x{pos_uuid_hex[16:]}"],
                "src": str(close_order["src"]),
            }
        )

    actual_len = len(signals)
    if actual_len == 0:
        print(f"Warning: No valid order pairs found for hotkey {hotkey}")
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
    ] * (MAX_SIGNALS - actual_len)

    print(f"Successfully prepared {actual_len} signals.")
    return padded_signals, actual_len


def parse_witness_from_gz(gz_path):
    """
    Decompresses and parses a Nargo witness file from its raw binary format.
    """
    PRIME = (
        21888242871839275222246405745257275088548364400416034343698204186575808495617
    )

    with gzip.open(gz_path, "rb") as f:
        witness_data = f.read()

    witness_count = int.from_bytes(witness_data[:4], "big")

    witnesses = []
    offset = 4
    for _ in range(witness_count):
        if offset + 32 > len(witness_data):
            break

        value_bytes = witness_data[offset : offset + 32]
        value = int.from_bytes(value_bytes, "big")

        # The values are field elements, so they should already be in the range [0, P-1].
        # We just need to convert them to strings for the TOML file.
        witnesses.append(str(value))
        offset += 32

    return witnesses


def run_merkle_generator(signals, actual_len):
    """
    Runs the merkle_generator circuit and parses the witness file to get the output.
    """
    print("\nStep 2: Running Merkle Generator circuit...")

    merkle_input = {"signals": signals, "actual_len": actual_len}

    witness_name = "merkle_witness"
    witness_path = os.path.join(TREE_GEN_DIR, "target", f"{witness_name}.gz")

    with open(TREE_GEN_PROVER_TOML, "w") as f:
        toml.dump(merkle_input, f)

    print("Executing nargo... (This might take a moment)")
    result = subprocess.run(
        ["nargo", "execute", witness_name, "--silence-warnings"],
        cwd=TREE_GEN_DIR,
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


def run_main_prover(signals, actual_len, merkle_root, path_elements, path_indices):
    """
    Runs the main scoring circuit with all the necessary data.
    """
    print("\nStep 3: Running main prover circuit...")

    # The RISK_FREE_RATE in the circuit is an i64.
    # Let's provide it scaled, assuming 4 decimal places of precision in the circuit.
    risk_free_rate_scaled = int((RISK_FREE_RATE_ANNUAL_PERCENT / 100) * 10000)

    main_input = {
        "signals": signals,
        "actual_len": actual_len,
        "merkle_root": merkle_root,
        "path_elements": path_elements,
        "path_indices": path_indices,
        "RISK_FREE_RATE": str(risk_free_rate_scaled),
    }

    with open(MAIN_PROVER_TOML, "w") as f:
        toml.dump(main_input, f)

    print("Compiling main circuit...")
    subprocess.run(["nargo", "compile"], cwd=CIRCUITS_DIR, check=True)

    witness_name = "main_witness"
    witness_path = os.path.join(CIRCUITS_DIR, "target", f"{witness_name}.gz")
    print(f"Generating witness for main circuit... witness name: {witness_name}")
    subprocess.run(
        ["nargo", "execute", witness_name, "--silence-warnings"],
        cwd=CIRCUITS_DIR,
        check=True,
    )

    print("Running barretenberg to generate proof...")
    acir_path = os.path.join(CIRCUITS_DIR, "target", "circuits.json")
    proof_dir = os.path.join(CIRCUITS_DIR, "proofs")
    proof_path = os.path.join(proof_dir, "proof")

    os.makedirs(proof_dir, exist_ok=True)

    subprocess.run(
        ["bb", "prove", "-b", acir_path, "-w", witness_path, "-o", proof_dir],
        check=True,
    )

    print("\n--- PROOF GENERATED SUCCESSFULLY! ---")
    print(f"Proof written to {proof_path}")


if __name__ == "__main__":
    # 1. Prepare data from the main checkpoint file
    signals, actual_len = prepare_signals_from_checkpoint(
        CHECKPOINT_FILE, TARGET_HOTKEY
    )
    if not signals or actual_len == 0:
        print("Could not prepare signals. Exiting.")
        exit(1)

    # 2. Run Merkle Generator
    merkle_data = run_merkle_generator(signals, actual_len)
    if not merkle_data:
        print("\nHalting due to error in Merkle generation.")
        exit(1)

    merkle_root, path_elements, path_indices = merkle_data

    # 3. Run Main Prover
    run_main_prover(signals, actual_len, merkle_root, path_elements, path_indices)

    # 4. Clean up temporary files
    if os.path.exists(TREE_GEN_PROVER_TOML):
        os.remove(TREE_GEN_PROVER_TOML)

    merkle_witness_path = os.path.join(TREE_GEN_DIR, "target", "merkle_witness.gz")
    if os.path.exists(merkle_witness_path):
        os.remove(merkle_witness_path)

    main_witness_path = os.path.join(CIRCUITS_DIR, "target", "main_witness.gz")
    if os.path.exists(main_witness_path):
        os.remove(main_witness_path)

    print("\nAll steps completed.")

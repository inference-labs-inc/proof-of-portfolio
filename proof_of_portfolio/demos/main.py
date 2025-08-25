import json

from ..proof_generator import generate_proof


def main(args):
    """Demo main function - thin wrapper around core proof generation logic."""
    hotkey = args.hotkey
    print("Loading data from validator_checkpoint.json...")
    with open("validator_checkpoint.json", "r") as f:
        data = json.load(f)

    if hotkey:
        if hotkey not in data["perf_ledgers"]:
            print(f"Error: Hotkey '{hotkey}' not found in validator checkpoint data.")
            print(f"Available hotkeys: {list(data['perf_ledgers'].keys())}")
            return
        miner_hotkey = hotkey
    else:
        miner_hotkey = list(data["perf_ledgers"].keys())[0]
        print(f"No hotkey specified, using first available: {miner_hotkey}")

    return generate_proof(data, miner_hotkey)


if __name__ == "__main__":
    import argparse

    parser = argparse.ArgumentParser(
        description="Generate a zero-knowledge proof for a miner's portfolio data."
    )
    parser.add_argument(
        "--hotkey",
        type=str,
        help="The hotkey of the miner to generate a proof for. If not provided, uses the first available miner.",
    )

    args = parser.parse_args()
    main(args)

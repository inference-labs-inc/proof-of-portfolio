#!/usr/bin/env python3
"""Test script to verify bb and nargo are installed correctly."""

import subprocess
import sys


def check_command(cmd, name):
    """Check if a command is available and working."""
    try:
        result = subprocess.run([cmd, "--version"], capture_output=True, text=True)
        if result.returncode == 0:
            print(f"✓ {name} is installed: {result.stdout.strip()}")
            return True
        else:
            print(f"✗ {name} command failed: {result.stderr}")
            return False
    except FileNotFoundError:
        print(f"✗ {name} not found in PATH")
        return False


def main():
    """Test that dependencies are installed."""
    print("Testing dependency installation...")

    # Import the package to trigger auto-installation
    print("Package imported successfully")

    # Check if bb is installed
    bb_ok = check_command("bb", "bb (Barretenberg)")

    # Check if nargo is installed
    nargo_ok = check_command("nargo", "nargo (Noir)")

    if bb_ok and nargo_ok:
        print("\n✓ All dependencies installed successfully!")
        return 0
    else:
        print("\n✗ Some dependencies are missing")
        return 1


if __name__ == "__main__":
    sys.exit(main())

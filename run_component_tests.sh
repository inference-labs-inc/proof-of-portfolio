#!/bin/bash

TEMP_DIR=$(mktemp -d)
trap "rm -rf $TEMP_DIR" EXIT

echo "Creating test runner in $TEMP_DIR..."

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

cp -r "$SCRIPT_DIR/proof_of_portfolio/circuits/components" "$TEMP_DIR/components_standalone"

echo "Running tests..."
cd "$TEMP_DIR/components_standalone" && nargo test "$@"

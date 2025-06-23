#!/bin/bash

# install.sh - Installation script for Proof of Portfolio
# This script installs all dependencies needed to run the project

set -e  # Exit on error

# Parse command line arguments
INSTALL_BIGNUM=false
INSTALL_BARRETENBERG=false
INTERACTIVE=true

print_usage() {
    echo "Usage: $0 [OPTIONS]"
    echo "Install dependencies for Proof of Portfolio"
    echo ""
    echo "Options:"
    echo "  -h, --help                 Display this help message"
    echo "  -n, --non-interactive      Run in non-interactive mode"
    echo "  -b, --with-bignum          Install noir-bignum"
    echo "  -r, --with-barretenberg    Install Barretenberg"
    echo "  --all                      Install all dependencies"
    echo ""
    echo "Example:"
    echo "  $0 --all                   Install all dependencies without prompts"
    echo "  $0                         Run in interactive mode"
}

# Parse command line options
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            print_usage
            exit 0
            ;;
        -n|--non-interactive)
            INTERACTIVE=false
            shift
            ;;
        -b|--with-bignum)
            INSTALL_BIGNUM=true
            shift
            ;;
        -r|--with-barretenberg)
            INSTALL_BARRETENBERG=true
            shift
            ;;
        --all)
            INSTALL_BIGNUM=true
            INSTALL_BARRETENBERG=true
            INTERACTIVE=false
            shift
            ;;
        *)
            echo "Unknown option: $1"
            print_usage
            exit 1
            ;;
    esac
done

echo "Installing dependencies for Proof of Portfolio..."

# Check if noirup is already installed
if ! command -v noirup &> /dev/null; then
    echo "Installing noirup..."
    curl -L https://raw.githubusercontent.com/noir-lang/noirup/main/install | bash

    # Add noirup to PATH for the current session
    export PATH="$HOME/.noirup/bin:$PATH"
fi

# Install or update Noir
echo "Installing/updating Noir..."
noirup

# Verify Noir installation
if command -v nargo &> /dev/null; then
    echo "Noir successfully installed!"
    nargo --version
else
    echo "Failed to install Noir. Please check your PATH and try again."
    exit 1
fi

# Install noir-bignum (optional, for package management)
if [ "$INTERACTIVE" = true ] && [ "$INSTALL_BIGNUM" = false ]; then
    echo "Would you like to install noir-bignum for package management? (y/n)"
    read -r response
    if [[ "$response" =~ ^[Yy]$ ]]; then
        INSTALL_BIGNUM=true
    fi
fi

if [ "$INSTALL_BIGNUM" = true ]; then
    echo "Installing noir-bignum..."
    # Note: This is a placeholder. The actual installation command would depend on how noir-bignum is distributed.
    # As of now, noir-bignum would typically be added as a dependency in Nargo.toml
    echo "To use noir-bignum, add it as a dependency in your Nargo.toml file:"
    echo '[dependencies]'
    echo 'noir_bignum = { git = "https://github.com/shuklaayush/noir-bignum", tag = "v0.1.0" }'
fi

# Information about Barretenberg (optional, for proof generation)
if [ "$INTERACTIVE" = true ] && [ "$INSTALL_BARRETENBERG" = false ]; then
    echo "Barretenberg is required for proof generation. Would you like to install it? (y/n)"
    read -r response
    if [[ "$response" =~ ^[Yy]$ ]]; then
        INSTALL_BARRETENBERG=true
    fi
fi

if [ "$INSTALL_BARRETENBERG" = true ]; then
    echo "Installing Barretenberg..."
    # Note: This is a placeholder. The actual installation command would depend on how Barretenberg is distributed.
    # As of now, you would typically clone the repository and build it
    git clone https://github.com/AztecProtocol/barretenberg.git
    cd barretenberg
    # Follow build instructions from Barretenberg repository
    echo "Please follow the build instructions in the Barretenberg repository."
    echo "After building, make sure the 'bb' command is in your PATH."
fi

echo "Installation complete!"
echo "You can now run the project by following the instructions in the README.md"

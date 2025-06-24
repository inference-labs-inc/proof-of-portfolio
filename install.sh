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

# Initialize NOIRUP_CMD variable
NOIRUP_CMD=""

# Check if noirup is already installed
if command -v noirup &> /dev/null; then
    echo "noirup is already installed."
    NOIRUP_CMD="noirup"
else
    echo "Installing noirup..."
    curl -L https://raw.githubusercontent.com/noir-lang/noirup/main/install | bash

    # Add noirup to PATH for the current session
    export PATH="$HOME/.noirup/bin:$PATH"

    # Check if noirup is now in PATH
    if command -v noirup &> /dev/null; then
        echo "noirup successfully added to PATH."
        NOIRUP_CMD="noirup"
    else
        echo "noirup was installed but not found in PATH."
        echo "You may need to manually run: source ~/.bashrc (or ~/.zshrc)"
        echo "Trying to find noirup in common locations..."

        # Try common locations for noirup
        NOIRUP_PATHS=(
            "$HOME/.noirup/bin/noirup"
            "$HOME/.nargo/bin/noirup"
            "$HOME/.cargo/bin/noirup"
        )

        for path in "${NOIRUP_PATHS[@]}"; do
            if [ -x "$path" ]; then
                NOIRUP_CMD="$path"
                echo "Found noirup at: $NOIRUP_CMD"
                break
            fi
        done

        if [ -z "$NOIRUP_CMD" ]; then
            echo "Could not find noirup executable. Please restart your terminal and run this script again."
            exit 1
        fi
    fi
fi

# Install or update Noir
echo "Installing/updating Noir..."
$NOIRUP_CMD

# Verify Noir installation
if command -v nargo &> /dev/null; then
    echo "Noir successfully installed!"
    nargo --version
else
    echo "Nargo not found in PATH. Checking common locations..."

    # Try common locations for nargo
    NARGO_PATHS=(
        "$HOME/.nargo/bin/nargo"
        "$HOME/.noir/bin/nargo"
        "$HOME/.cargo/bin/nargo"
        "$HOME/.noirup/bin/nargo"
        "$(dirname "$NOIRUP_CMD")/nargo"
    )

    NARGO_FOUND=false
    for path in "${NARGO_PATHS[@]}"; do
        if [ -x "$path" ]; then
            echo "Found nargo at: $path"
            echo "Noir successfully installed!"
            "$path" --version
            NARGO_FOUND=true
            echo ""
            echo "To use nargo in your terminal, you may need to:"
            echo "1. Restart your terminal, or"
            echo "2. Run: source ~/.bashrc (or ~/.zshrc)"
            break
        fi
    done

    if [ "$NARGO_FOUND" = false ]; then
        echo "Nargo not found in common locations. Trying to use noirup to run nargo..."

        # Try to use noirup to run nargo directly
        if [ -n "$NOIRUP_CMD" ]; then
            echo "Using noirup to check nargo version..."
            if $NOIRUP_CMD nargo --version &> /dev/null; then
                echo "Noir is installed and can be accessed via noirup!"
                $NOIRUP_CMD nargo --version
                echo ""
                echo "To use nargo directly in your terminal, you need to:"
                echo "1. Restart your terminal, or"
                echo "2. Run: source ~/.bashrc (or ~/.zshrc)"
                echo ""
                echo "For now, the installation will continue, but you may need to use noirup to run nargo commands."
                NARGO_FOUND=true
            else
                echo "Failed to run nargo via noirup."
            fi
        fi

        if [ "$NARGO_FOUND" = false ]; then
            echo "Failed to install Noir. Please check your PATH and try again."
            echo "You may need to restart your terminal and run this script again."
            echo ""
            echo "If you've just installed noirup, try the following steps:"
            echo "1. Close this terminal and open a new one"
            echo "2. Run: ./install.sh"
            echo ""
            echo "If the issue persists, try manually installing Noir:"
            echo "1. Run: curl -L https://raw.githubusercontent.com/noir-lang/noirup/main/install | bash"
            echo "2. Open a new terminal"
            echo "3. Run: noirup"
            echo "4. Run: nargo --version"
            exit 1
        fi
    fi
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
    # Check if barretenberg directory already exists
    if [ -d "barretenberg" ]; then
        echo "Barretenberg directory already exists."

        if [ "$INTERACTIVE" = true ]; then
            echo "What would you like to do?"
            echo "1) Skip installation (barretenberg already exists)"
            echo "2) Update existing installation (git pull)"
            echo "3) Remove and reinstall"
            read -r choice

            case $choice in
                1)
                    echo "Skipping Barretenberg installation."
                    ;;
                2)
                    echo "Updating existing Barretenberg installation..."
                    (cd barretenberg && git pull)
                    echo "Barretenberg updated."
                    ;;
                3)
                    echo "Removing existing Barretenberg installation..."
                    rm -rf barretenberg
                    echo "Cloning Barretenberg repository..."
                    git clone https://github.com/AztecProtocol/barretenberg.git
                    echo "Barretenberg cloned successfully."
                    ;;
                *)
                    echo "Invalid choice. Skipping Barretenberg installation."
                    ;;
            esac
        else
            # In non-interactive mode, default to updating
            echo "Updating existing Barretenberg installation..."
            (cd barretenberg && git pull)
            echo "Barretenberg updated."
        fi
    else
        # Directory doesn't exist, clone the repository
        echo "Cloning Barretenberg repository..."
        git clone https://github.com/AztecProtocol/barretenberg.git
        echo "Barretenberg cloned successfully."
    fi

    if [ -d "barretenberg" ]; then
        echo "Please follow the build instructions in the Barretenberg repository."
        echo "After building, make sure the 'bb' command is in your PATH."
    fi
fi

echo "Installation complete!"
echo "You can now run the project by following the instructions in the README.md"

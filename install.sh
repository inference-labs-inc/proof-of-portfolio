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

    # Initialize BBUP_CMD variable
    BBUP_CMD=""

    # Check if bbup is already installed
    if command -v bbup &> /dev/null; then
        echo "bbup is already installed."
        BBUP_CMD="bbup"
    else
        echo "Installing bbup..."
        curl -L https://raw.githubusercontent.com/AztecProtocol/aztec-packages/refs/heads/master/barretenberg/bbup/install | bash

        # Add bbup to PATH for the current session
        export PATH="$HOME/.bbup/bin:$PATH"
        export PATH="$HOME/bin:$PATH"
        export PATH="$HOME/.local/bin:$PATH"

        # Check if bbup is now in PATH
        if command -v bbup &> /dev/null; then
            echo "bbup successfully added to PATH."
            BBUP_CMD="bbup"
        else
            echo "bbup was installed but not found in PATH."
            echo "You may need to manually run: source ~/.bashrc (or ~/.zshrc)"
            echo "Trying to find bbup in common locations..."

            # Try common locations for bbup
            BBUP_PATHS=(
                "$HOME/.bbup/bin/bbup"
                "$HOME/.local/bin/bbup"
                "$HOME/.cargo/bin/bbup"
                "$HOME/bin/bbup"
                "$HOME/.nargo/bin/bbup"  # Similar to noirup
            )

            for path in "${BBUP_PATHS[@]}"; do
                if [ -x "$path" ]; then
                    BBUP_CMD="$path"
                    echo "Found bbup at: $BBUP_CMD"

                    # Add the directory to PATH for the current session
                    export PATH="$(dirname "$path"):$PATH"
                    break
                fi
            done

            if [ -z "$BBUP_CMD" ]; then
                # Try to find the bbup installation script to see where it might have installed bbup
                echo "Searching for bbup installation files..."
                BBUP_INSTALL_PATHS=(
                    "$HOME/.bbup/install"
                    "$HOME/.bbup/bbup"
                    "$HOME/bin/bbup"
                    "$HOME/.local/bin/bbup"
                )

                for path in "${BBUP_INSTALL_PATHS[@]}"; do
                    if [ -f "$path" ]; then
                        echo "Found bbup installation file at: $path"
                        # Try to extract installation directory from the file
                        INSTALL_DIR=$(grep -o "INSTALL_DIR=.*" "$path" | cut -d'=' -f2 || echo "")
                        if [ -n "$INSTALL_DIR" ]; then
                            echo "bbup installation directory might be: $INSTALL_DIR"
                            if [ -x "$INSTALL_DIR/bbup" ]; then
                                BBUP_CMD="$INSTALL_DIR/bbup"
                                echo "Found bbup at: $BBUP_CMD"

                                # Add the directory to PATH for the current session
                                export PATH="$INSTALL_DIR:$PATH"
                                break
                            fi
                        fi
                    fi
                done
            fi

            if [ -z "$BBUP_CMD" ]; then
                echo "Could not find bbup executable. Please restart your terminal and run this script again."
                echo "If the issue persists, try manually installing bbup:"
                echo "curl -L https://raw.githubusercontent.com/AztecProtocol/aztec-packages/refs/heads/master/barretenberg/bbup/install | bash"
                echo ""
                echo "After installation, run:"
                echo "source ~/.bashrc  # or ~/.zshrc if you're using zsh"
                echo "bbup"
                exit 1
            fi
        fi
    fi

    # Function to run bbup with the correct environment variables
    run_bbup() {
        echo "Running bbup to install Barretenberg..."

        # Save the current PATH
        OLD_PATH="$PATH"

        # Add common directories to PATH
        export PATH="$HOME/.bbup/bin:$PATH"
        export PATH="$HOME/bin:$PATH"
        export PATH="$HOME/.local/bin:$PATH"
        export PATH="$HOME/.cargo/bin:$PATH"

        # Run bbup
        $BBUP_CMD

        # Check if bb is now in PATH
        if command -v bb &> /dev/null; then
            echo "bb successfully added to PATH."
            BB_CMD="bb"
        else
            # Try to find bb in common locations
            BB_PATHS=(
                "$HOME/.bbup/bin/bb"
                "$HOME/.local/bin/bb"
                "$HOME/.cargo/bin/bb"
                "$HOME/bin/bb"
                "$(dirname "$BBUP_CMD")/bb"
            )

            for path in "${BB_PATHS[@]}"; do
                if [ -x "$path" ]; then
                    BB_CMD="$path"
                    echo "Found bb at: $BB_CMD"

                    # Add the directory to PATH for the current session
                    export PATH="$(dirname "$path"):$PATH"
                    break
                fi
            done
        fi

        # Restore the original PATH if bb was not found
        if [ -z "$BB_CMD" ]; then
            export PATH="$OLD_PATH"
        fi
    }

    # Install or update Barretenberg using bbup
    echo "Installing/updating Barretenberg using bbup..."
    run_bbup

    # Verify Barretenberg installation
    if [ -n "$BB_CMD" ]; then
        # BB_CMD was set by run_bbup function
        echo "Barretenberg successfully installed!"
        $BB_CMD --version
        echo ""
        if [ "$BB_CMD" != "bb" ]; then
            echo "To use bb in your terminal, you may need to:"
            echo "1. Restart your terminal, or"
            echo "2. Run: source ~/.bashrc (or ~/.zshrc)"
            echo ""
            echo "For now, you can use the full path to bb:"
            echo "$BB_CMD"
        fi
    elif command -v bb &> /dev/null; then
        echo "Barretenberg successfully installed!"
        bb --version
        BB_CMD="bb"
    else
        echo "bb not found in PATH. Checking common locations..."

        # Try common locations for bb
        BB_PATHS=(
            "$HOME/.bbup/bin/bb"
            "$HOME/.local/bin/bb"
            "$HOME/.cargo/bin/bb"
            "$HOME/bin/bb"
            "$(dirname "$BBUP_CMD")/bb"
        )

        BB_FOUND=false
        for path in "${BB_PATHS[@]}"; do
            if [ -x "$path" ]; then
                echo "Found bb at: $path"
                echo "Barretenberg successfully installed!"
                "$path" --version
                BB_CMD="$path"
                BB_FOUND=true
                echo ""
                echo "To use bb in your terminal, you may need to:"
                echo "1. Restart your terminal, or"
                echo "2. Run: source ~/.bashrc (or ~/.zshrc)"
                echo ""
                echo "For now, you can use the full path to bb:"
                echo "$path"
                break
            fi
        done

        if [ "$BB_FOUND" = false ]; then
            # Try running bbup with the --info flag to see where it installed bb
            echo "Trying to get installation information from bbup..."
            if [ -n "$BBUP_CMD" ]; then
                BBUP_INFO=$($BBUP_CMD --info 2>/dev/null || echo "")
                if [ -n "$BBUP_INFO" ]; then
                    echo "bbup info: $BBUP_INFO"
                    # Try to extract the installation path from the info
                    BB_PATH=$(echo "$BBUP_INFO" | grep -o "installed.*bb" | sed 's/installed //g' || echo "")
                    if [ -n "$BB_PATH" ] && [ -x "$BB_PATH" ]; then
                        echo "Found bb at: $BB_PATH"
                        echo "Barretenberg successfully installed!"
                        "$BB_PATH" --version
                        BB_CMD="$BB_PATH"
                        BB_FOUND=true
                        echo ""
                        echo "To use bb in your terminal, you may need to:"
                        echo "1. Restart your terminal, or"
                        echo "2. Run: source ~/.bashrc (or ~/.zshrc)"
                        echo ""
                        echo "For now, you can use the full path to bb:"
                        echo "$BB_PATH"
                    fi
                fi
            fi
        fi

        if [ "$BB_FOUND" = false ]; then
            echo "Failed to find bb after installation. This could be because:"
            echo "1. The installation is still in progress"
            echo "2. The bb executable is not in your PATH"
            echo "3. The installation failed"
            echo ""
            echo "Please try the following steps:"
            echo "1. Close this terminal and open a new one"
            echo "2. Run: bbup"
            echo "3. Run: bb --version"
            echo ""
            echo "If the issue persists, try manually installing Barretenberg:"
            echo "1. Run: curl -L https://raw.githubusercontent.com/AztecProtocol/aztec-packages/refs/heads/master/barretenberg/bbup/install | bash"
            echo "2. Open a new terminal"
            echo "3. Run: bbup"
            echo "4. Run: bb --version"
            exit 1
        fi
    fi
fi

echo "Installation complete!"

# Provide a summary of the installation status
if [ "$INSTALL_BARRETENBERG" = true ]; then
    echo ""
    echo "Barretenberg Installation Summary:"
    if [ -n "$BB_CMD" ]; then
        if [ "$BB_CMD" = "bb" ]; then
            echo "✓ Barretenberg (bb) is installed and available in your PATH"
            echo "  You can run bb commands directly, e.g.: bb --version"
        else
            echo "✓ Barretenberg (bb) is installed but not in your PATH"
            echo "  You can run bb using the full path: $BB_CMD"
            echo "  Or add it to your PATH by running: source ~/.bashrc (or ~/.zshrc)"
            echo "  After restarting your terminal, you should be able to run: bb --version"
        fi
    else
        echo "! Barretenberg (bb) installation status is unknown"
        echo "  Please check if bb is available by running: bb --version"
        echo "  If not, try installing it manually with: bbup"
    fi
fi

echo ""
echo "You can now run the project by following the instructions in the README.md"

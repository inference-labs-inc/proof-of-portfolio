#!/bin/bash

set -e

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
    -h | --help)
        print_usage
        exit 0
        ;;
    -n | --non-interactive)
        INTERACTIVE=false
        shift
        ;;
    -b | --with-bignum)
        INSTALL_BIGNUM=true
        shift
        ;;
    -r | --with-barretenberg)
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

echo -e "\033[32mInstalling dependencies for Proof of Portfolio...\033[0m"

find_executable() {
    local exe_name=$1
    local install_dir=$2

    if command -v "$exe_name" &>/dev/null; then
        echo "$exe_name"
        return 0
    fi

    local paths=(
        "$HOME/$install_dir/bin/$exe_name"
        "$HOME/$install_dir/$exe_name"
        "$HOME/.local/bin/$exe_name"
        "$HOME/.cargo/bin/$exe_name"
        "$HOME/bin/$exe_name"
        "$HOME/.nargo/bin/$exe_name"
        "$HOME/.noir/bin/$exe_name"
    )

    for path in "${paths[@]}"; do
        if [ -x "$path" ]; then
            echo "$path"
            return 0
        fi
    done

    return 1
}

add_to_path() {
    local dir=$1
    if [[ ":$PATH:" != *":$dir:"* ]]; then
        export PATH="$dir:$PATH"
    fi
}

refresh_path() {
    add_to_path "$HOME/.noirup/bin"
    add_to_path "$HOME/.nargo/bin"
    add_to_path "$HOME/.bb"
    add_to_path "$HOME/.local/bin"
    add_to_path "$HOME/.cargo/bin"
    add_to_path "$HOME/bin"
}

install_noir() {
    echo -e "\033[34mInstalling/updating Noir...\033[0m"

    NOIRUP_CMD=$(find_executable "noirup" ".noirup" || true)

    if [ -z "$NOIRUP_CMD" ]; then
        echo "Installing noirup..."
        curl -L https://raw.githubusercontent.com/noir-lang/noirup/main/install | bash
        refresh_path
        NOIRUP_CMD=$(find_executable "noirup" ".noirup" || true)

        if [ -z "$NOIRUP_CMD" ]; then
            echo -e "\033[31mFailed to install noirup. Please restart your terminal and try again.\033[0m"
            exit 1
        fi
    fi

    echo "Found noirup at: $NOIRUP_CMD"
    $NOIRUP_CMD

    refresh_path
    NARGO_CMD=$(find_executable "nargo" ".nargo" || true)

    if [ -n "$NARGO_CMD" ]; then
        echo -e "\033[32mNoir successfully installed!\033[0m"
        $NARGO_CMD --version
    else
        echo -e "\033[31mFailed to install Noir. Please restart your terminal and try again.\033[0m"
        exit 1
    fi
}

install_barretenberg() {
    echo -e "\033[34mInstalling/updating Barretenberg...\033[0m"

    BBUP_CMD=$(find_executable "bbup" ".bb" || true)

    if [ -z "$BBUP_CMD" ]; then
        echo "Installing bbup..."
        curl -L https://raw.githubusercontent.com/AztecProtocol/aztec-packages/refs/heads/master/barretenberg/bbup/install | bash
        refresh_path
        BBUP_CMD=$(find_executable "bbup" ".bb" || true)

        if [ -z "$BBUP_CMD" ]; then
            echo -e "\033[31mFailed to install bbup. Please restart your terminal and try again.\033[0m"
            exit 1
        fi
    fi

    echo "Found bbup at: $BBUP_CMD"
    echo "Installing bb version 0.87.0..."
    $BBUP_CMD --version 0.87.0

    refresh_path
    BB_CMD=$(find_executable "bb" ".bb" || true)

    if [ -n "$BB_CMD" ]; then
        echo -e "\033[32mBarretenberg successfully installed!\033[0m"
        $BB_CMD --version
    else
        echo -e "\033[31mFailed to install Barretenberg. Please restart your terminal and try again.\033[0m"
        exit 1
    fi
}

install_noir

if [ "$INTERACTIVE" = true ] && [ "$INSTALL_BIGNUM" = false ]; then
    echo "Would you like to install noir-bignum for package management? (y/n)"
    read -r response
    if [[ $response =~ ^[Yy]$ ]]; then
        INSTALL_BIGNUM=true
    fi
fi

if [ "$INSTALL_BIGNUM" = true ]; then
    echo "To use noir-bignum, add it as a dependency in your Nargo.toml file:"
    echo '[dependencies]'
    echo 'noir_bignum = { git = "https://github.com/shuklaayush/noir-bignum", tag = "v0.1.0" }'
fi

if [ "$INTERACTIVE" = true ] && [ "$INSTALL_BARRETENBERG" = false ]; then
    echo "Barretenberg is required for proof generation. Would you like to install it? (y/n)"
    read -r response
    if [[ $response =~ ^[Yy]$ ]]; then
        INSTALL_BARRETENBERG=true
    fi
fi

if [ "$INSTALL_BARRETENBERG" = true ]; then
    install_barretenberg
fi

echo -e "\033[34mInstalling the Proof of Portfolio CLI...\033[0m"

if command -v pip &>/dev/null; then
    echo "Installing the pop CLI using pip..."
    pip install -e .

    if command -v pop &>/dev/null; then
        echo -e "\033[32mProof of Portfolio CLI (pop) successfully installed!\033[0m"
        pop --version
    else
        echo -e "\033[33mThe pop CLI was not found in PATH after installation.\033[0m"
        echo "You may need to restart your terminal or add the installation directory to your PATH."
    fi
else
    echo -e "\033[33mpip not found. Cannot install the pop CLI automatically.\033[0m"
    echo "Please install pip and then run: pip install -e ."
fi

echo ""
echo -e "\033[32mInstallation complete!\033[0m"
echo ""
echo "Summary:"
echo "--------"

if command -v nargo &>/dev/null || [ -n "$(find_executable "nargo" ".nargo" || true)" ]; then
    echo -e "\033[32mNoir (nargo) is installed\033[0m"
else
    echo -e "\033[31mNoir (nargo) is NOT installed\033[0m"
fi

if [ "$INSTALL_BARRETENBERG" = true ]; then
    if command -v bb &>/dev/null || [ -n "$(find_executable "bb" ".bb" || true)" ]; then
        echo -e "\033[32mBarretenberg (bb) is installed\033[0m"
    else
        echo -e "\033[31mBarretenberg (bb) is NOT installed\033[0m"
    fi
fi

if command -v pop &>/dev/null; then
    echo -e "\033[32mProof of Portfolio CLI (pop) is installed\033[0m"
else
    echo -e "\033[31mProof of Portfolio CLI (pop) is NOT installed\033[0m"
fi

echo ""
echo "If any tools are not in your PATH, restart your terminal or run:"
echo "  source ~/.bashrc  # or ~/.zshrc for zsh users"
echo ""
echo "You can now run the project using the 'pop' command. For more information, see the README.md"

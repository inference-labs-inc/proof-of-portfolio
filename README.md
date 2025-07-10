# Proof of Portfolio (PoP)

A command-line interface for the Proof of Portfolio system.

## Installation

### Recommended: Using the installer script

The easiest way to install the Proof of Portfolio CLI and all its dependencies is to use the provided installer script:

```bash
# Clone the repository
git clone https://github.com/yourusername/proof-of-portfolio.git
cd proof-of-portfolio

# Run the installer script
./install.sh
```

This will install all required dependencies and the `pop` command-line tool automatically.

For advanced installation options, run `./install.sh --help`.

### Alternative: Manual installation using pip

If you prefer, you can also install the package manually using pip:

```bash
# Clone the repository
git clone https://github.com/yourusername/proof-of-portfolio.git
cd proof-of-portfolio

# Install the package
pip install -e .
```

This will install the `pop` command-line tool, but you'll need to install other dependencies manually.

## Usage

The Proof of Portfolio CLI provides five main commands:

### 1. Generate a Merkle Tree (for Miners)

As a miner, you can generate your own Merkle tree and scores using your data.json file:

```bash
pop generate-tree --path path/to/data.json [--hotkey YOUR_HOTKEY] [--output path/to/output/tree.json]
# OR
pop generate-tree --path path/to/hotkey/directory [--hotkey YOUR_HOTKEY] [--output path/to/output/tree.json]
```

If the `--hotkey` option is not provided, the CLI will try to extract it from the parent directory name.

If the `--output` option is not provided, the tree.json file will be saved to the same directory as the data.json file.

### 2. Validate a Miner (for Validators)

As a validator, you can generate a tree for a miner given their data.json file or directory:

```bash
pop validate --path path/to/miner/data.json
# OR
pop validate --path path/to/miner/directory
```

### 3. Validate All Miners (for Validators)

As a validator, you can generate trees for ALL miners given a directory or input JSON file:

```bash
pop validate-all --path path/to/children/directory
# OR
pop validate-all --path path/to/input_data.json
```

If you provide a directory path, it will process all miner directories directly. If you provide a JSON file path, it will split the file into subdirectories for each miner, and then generate a Merkle tree for each one.

### 4. Save a Merkle Tree

You can save a merkle tree from an existing tree.json file or a hotkey directory to a specified location:

```bash
pop save-tree --path path/to/tree.json --output path/to/output/tree.json
# OR
pop save-tree --path path/to/hotkey/directory --output path/to/output/tree.json
```

This will load the merkle tree and save it to the specified location.

### 5. Analyze Data

You can analyze input data and split it into separate files for each hotkey:

```bash
pop analyse-data --path path/to/input_data.json [--output path/to/output/directory]
```

This will process the input JSON file and create a subdirectory for each hotkey, containing their respective data.json files. If the `--output` option is not provided, the files will be saved to a 'children' directory in the same location as the input file.

### Help

You can get help for any command using the `--help` option:

```bash
pop --help
pop generate-tree --help
pop validate --help
pop validate-all --help
pop save-tree --help
pop analyse-data --help
```

### Version

You can check the version of the CLI using the `--version` option:

```bash
pop --version
```

## File Structure

The Proof of Portfolio system uses the following file structure:

```
data/
├── input_data.json           # Input data containing all miners' data
├── scores_summary.json       # Summary of all miners' scores
└── children/                 # Directory containing subdirectories for each miner
    ├── MINER_HOTKEY_1/       # Subdirectory for miner 1
    │   ├── data.json         # Miner 1's data
    │   ├── tree.json         # Miner 1's Merkle tree
    │   └── score.json        # Miner 1's score
    └── MINER_HOTKEY_2/       # Subdirectory for miner 2
        ├── data.json         # Miner 2's data
        ├── tree.json         # Miner 2's Merkle tree
        └── score.json        # Miner 2's score
```

# Table of Contents

* [proof\_of\_portfolio](#proof_of_portfolio)
  * [ensure\_dependencies](#proof_of_portfolio.ensure_dependencies)
  * [requires\_dependencies](#proof_of_portfolio.requires_dependencies)
  * [prove](#proof_of_portfolio.prove)
  * [save\_instant\_mdd\_results](#proof_of_portfolio.save_instant_mdd_results)
  * [get\_latest\_instant\_mdd\_for\_miner](#proof_of_portfolio.get_latest_instant_mdd_for_miner)
  * [get\_all\_instant\_mdd\_for\_miner](#proof_of_portfolio.get_all_instant_mdd_for_miner)
  * [prove\_instant\_mdd](#proof_of_portfolio.prove_instant_mdd)
  * [prove\_sync](#proof_of_portfolio.prove_sync)
* [proof\_of\_portfolio.validator](#proof_of_portfolio.validator)
  * [score\_child](#proof_of_portfolio.validator.score_child)
  * [score\_all](#proof_of_portfolio.validator.score_all)
* [proof\_of\_portfolio.miner](#proof_of_portfolio.miner)
  * [Miner](#proof_of_portfolio.miner.Miner)
    * [prepare\_signals\_from\_data](#proof_of_portfolio.miner.Miner.prepare_signals_from_data)
    * [run\_merkle\_generator](#proof_of_portfolio.miner.Miner.run_merkle_generator)
    * [generate\_tree](#proof_of_portfolio.miner.Miner.generate_tree)
    * [visualize\_tree](#proof_of_portfolio.miner.Miner.visualize_tree)
* [proof\_of\_portfolio.circuits.generate\_inputs](#proof_of_portfolio.circuits.generate_inputs)
  * [SCALE](#proof_of_portfolio.circuits.generate_inputs.SCALE)
  * [load\_validator\_checkpoint](#proof_of_portfolio.circuits.generate_inputs.load_validator_checkpoint)
  * [extract\_checkpoint\_data](#proof_of_portfolio.circuits.generate_inputs.extract_checkpoint_data)
  * [extract\_trading\_signals](#proof_of_portfolio.circuits.generate_inputs.extract_trading_signals)
  * [create\_signals\_toml](#proof_of_portfolio.circuits.generate_inputs.create_signals_toml)
  * [run\_tree\_generator](#proof_of_portfolio.circuits.generate_inputs.run_tree_generator)
  * [pad\_arrays](#proof_of_portfolio.circuits.generate_inputs.pad_arrays)
  * [format\_2d\_array\_for\_toml](#proof_of_portfolio.circuits.generate_inputs.format_2d_array_for_toml)
  * [generate\_prover\_toml](#proof_of_portfolio.circuits.generate_inputs.generate_prover_toml)
  * [main](#proof_of_portfolio.circuits.generate_inputs.main)
* [proof\_of\_portfolio.min\_metrics](#proof_of_portfolio.min_metrics)
  * [MinMetrics](#proof_of_portfolio.min_metrics.MinMetrics)
    * [weighting\_distribution](#proof_of_portfolio.min_metrics.MinMetrics.weighting_distribution)
    * [average](#proof_of_portfolio.min_metrics.MinMetrics.average)
    * [variance](#proof_of_portfolio.min_metrics.MinMetrics.variance)
    * [ann\_excess\_return](#proof_of_portfolio.min_metrics.MinMetrics.ann_excess_return)
    * [ann\_volatility](#proof_of_portfolio.min_metrics.MinMetrics.ann_volatility)
    * [ann\_downside\_volatility](#proof_of_portfolio.min_metrics.MinMetrics.ann_downside_volatility)
    * [daily\_max\_drawdown](#proof_of_portfolio.min_metrics.MinMetrics.daily_max_drawdown)
    * [sharpe](#proof_of_portfolio.min_metrics.MinMetrics.sharpe)
    * [omega](#proof_of_portfolio.min_metrics.MinMetrics.omega)
    * [statistical\_confidence](#proof_of_portfolio.min_metrics.MinMetrics.statistical_confidence)
    * [sortino](#proof_of_portfolio.min_metrics.MinMetrics.sortino)
* [proof\_of\_portfolio.analyze\_data](#proof_of_portfolio.analyze_data)
  * [split\_input\_json](#proof_of_portfolio.analyze_data.split_input_json)
* [proof\_of\_portfolio.post\_install](#proof_of_portfolio.post_install)
  * [refresh\_shell\_environment](#proof_of_portfolio.post_install.refresh_shell_environment)
  * [install\_noirup](#proof_of_portfolio.post_install.install_noirup)
  * [install\_nargo](#proof_of_portfolio.post_install.install_nargo)
  * [install\_bbup](#proof_of_portfolio.post_install.install_bbup)
  * [install\_bb](#proof_of_portfolio.post_install.install_bb)
* [proof\_of\_portfolio.signal\_processor](#proof_of_portfolio.signal_processor)
  * [parse\_order\_string](#proof_of_portfolio.signal_processor.parse_order_string)
  * [load\_processed\_signals](#proof_of_portfolio.signal_processor.load_processed_signals)
  * [sort\_signals\_chronologically](#proof_of_portfolio.signal_processor.sort_signals_chronologically)
  * [extract\_validator\_orders](#proof_of_portfolio.signal_processor.extract_validator_orders)
  * [generate\_validator\_trees](#proof_of_portfolio.signal_processor.generate_validator_trees)
  * [get\_validator\_tree\_hashes](#proof_of_portfolio.signal_processor.get_validator_tree_hashes)
* [proof\_of\_portfolio.parsing\_utils](#proof_of_portfolio.parsing_utils)
  * [parse\_single\_field\_output](#proof_of_portfolio.parsing_utils.parse_single_field_output)
  * [field\_to\_signed\_int](#proof_of_portfolio.parsing_utils.field_to_signed_int)
  * [parse\_demo\_output](#proof_of_portfolio.parsing_utils.parse_demo_output)
  * [parse\_nargo\_struct\_output](#proof_of_portfolio.parsing_utils.parse_nargo_struct_output)
  * [parse\_nested\_arrays](#proof_of_portfolio.parsing_utils.parse_nested_arrays)
* [proof\_of\_portfolio.main](#proof_of_portfolio.main)
  * [generate\_tree](#proof_of_portfolio.main.generate_tree)
  * [validate\_miner](#proof_of_portfolio.main.validate_miner)
  * [validate\_all\_miners](#proof_of_portfolio.main.validate_all_miners)
  * [analyse\_data](#proof_of_portfolio.main.analyse_data)
  * [save\_tree](#proof_of_portfolio.main.save_tree)
  * [print\_header](#proof_of_portfolio.main.print_header)
  * [check\_dependencies](#proof_of_portfolio.main.check_dependencies)
  * [main](#proof_of_portfolio.main.main)
* [proof\_of\_portfolio.demos.generate\_input\_data](#proof_of_portfolio.demos.generate_input_data)
  * [generate\_random\_data](#proof_of_portfolio.demos.generate_input_data.generate_random_data)
  * [main](#proof_of_portfolio.demos.generate_input_data.main)
* [proof\_of\_portfolio.demos.main](#proof_of_portfolio.demos.main)
  * [main](#proof_of_portfolio.demos.main.main)
* [proof\_of\_portfolio.proof\_generator](#proof_of_portfolio.proof_generator)
  * [SCALE](#proof_of_portfolio.proof_generator.SCALE)
  * [get\_attr](#proof_of_portfolio.proof_generator.get_attr)
  * [scale\_to\_int](#proof_of_portfolio.proof_generator.scale_to_int)
  * [scale\_from\_int](#proof_of_portfolio.proof_generator.scale_from_int)
  * [upload\_proof](#proof_of_portfolio.proof_generator.upload_proof)
  * [save\_zk\_results](#proof_of_portfolio.proof_generator.save_zk_results)
  * [get\_latest\_merkle\_root\_for\_miner](#proof_of_portfolio.proof_generator.get_latest_merkle_root_for_miner)
  * [get\_all\_results\_for\_miner](#proof_of_portfolio.proof_generator.get_all_results_for_miner)
* [proof\_of\_portfolio.verifier](#proof_of_portfolio.verifier)
  * [ensure\_bb\_installed](#proof_of_portfolio.verifier.ensure_bb_installed)
  * [verify](#proof_of_portfolio.verifier.verify)

<a id="proof_of_portfolio"></a>

# proof\_of\_portfolio

<a id="proof_of_portfolio.ensure_dependencies"></a>

#### ensure\_dependencies

```python
def ensure_dependencies()
```

Ensure bb and nargo are installed before running package functions.

<a id="proof_of_portfolio.requires_dependencies"></a>

#### requires\_dependencies

```python
def requires_dependencies(func)
```

Decorator to ensure dependencies are installed before running a function.

<a id="proof_of_portfolio.prove"></a>

#### prove

```python
@requires_dependencies
async def prove(miner_data,
                daily_pnl=None,
                hotkey=None,
                verbose=False,
                vali_config=None,
                use_weighting=False,
                bypass_confidence=False,
                daily_checkpoints=2,
                account_size=None,
                witness_only=False,
                wallet=None,
                augmented_scores=None)
```

Generate zero-knowledge proof for miner portfolio data asynchronously.

**Arguments**:

- `miner_data` - Dictionary containing perf_ledgers and positions for the miner
- `hotkey` - Miner's hotkey
- `verbose` - Boolean to control logging verbosity


**Returns**:

  Dictionary with proof results including status, portfolio_metrics, etc.

<a id="proof_of_portfolio.save_instant_mdd_results"></a>

#### save\_instant\_mdd\_results

```python
def save_instant_mdd_results(results, hotkey)
```

Save instant MDD proof results to disk in ~/.pop/instant_mdd/ directory.

**Arguments**:

- `results` - The instant MDD results dictionary to save
- `hotkey` - The miner's hotkey for filename

<a id="proof_of_portfolio.get_latest_instant_mdd_for_miner"></a>

#### get\_latest\_instant\_mdd\_for\_miner

```python
def get_latest_instant_mdd_for_miner(hotkey)
```

Get the latest instant MDD result for a specific miner.

**Arguments**:

- `hotkey` - The miner's hotkey


**Returns**:

  dict with latest instant MDD result, or None if not found

<a id="proof_of_portfolio.get_all_instant_mdd_for_miner"></a>

#### get\_all\_instant\_mdd\_for\_miner

```python
def get_all_instant_mdd_for_miner(hotkey)
```

Get all instant MDD results for a specific miner.

**Arguments**:

- `hotkey` - The miner's hotkey


**Returns**:

  list of instant MDD result dictionaries sorted by timestamp (newest first)

<a id="proof_of_portfolio.prove_instant_mdd"></a>

#### prove\_instant\_mdd

```python
@requires_dependencies
def prove_instant_mdd(hotkey, ledger_element)
```

Generate zero-knowledge proof for instant maximum drawdown calculation.

**Arguments**:

- `hotkey` - Miner's hotkey for identification
- `ledger_element` - PerfLedger object containing checkpoint data


**Returns**:

  Dictionary with proof results including drawdown calculation

<a id="proof_of_portfolio.prove_sync"></a>

#### prove\_sync

```python
def prove_sync(miner_data,
               daily_pnl=None,
               hotkey=None,
               verbose=False,
               vali_config=None,
               use_weighting=False,
               bypass_confidence=False,
               daily_checkpoints=2,
               account_size=None,
               witness_only=False,
               wallet=None,
               augmented_scores=None)
```

Synchronous wrapper for the prove function for backward compatibility.

**Arguments**:

- `miner_data` - Dictionary containing perf_ledgers and positions for the miner
- `hotkey` - Miner's hotkey
- `verbose` - Boolean to control logging verbosity


**Returns**:

  Dictionary with proof results including status, portfolio_metrics, etc.

<a id="proof_of_portfolio.validator"></a>

# proof\_of\_portfolio.validator

validator.py

This script processes data from data/input.json, splits it into subdirectories for each hotkey,
and scores each child by generating a Merkle tree for their data.

<a id="proof_of_portfolio.validator.score_child"></a>

#### score\_child

```python
@requires_dependencies
def score_child(hotkey_dir: str)
```

Scores a single child by generating a Merkle tree for their data.

**Arguments**:

- `hotkey_dir` _str_ - Path to the child's directory


**Returns**:

- `dict` - Score data for the child, or None if failed

<a id="proof_of_portfolio.validator.score_all"></a>

#### score\_all

```python
@requires_dependencies
def score_all(input_json_path: str = "data/input_data.json")
```

Processes input.json, splits it into subdirectories for each hotkey,
and scores each child by generating a Merkle tree for their data.

**Arguments**:

- `input_json_path` _str_ - Path to the input JSON file


**Returns**:

- `dict` - Dictionary mapping hotkeys to their scores

<a id="proof_of_portfolio.miner"></a>

# proof\_of\_portfolio.miner

<a id="proof_of_portfolio.miner.Miner"></a>

## Miner Objects

```python
class Miner()
```

<a id="proof_of_portfolio.miner.Miner.prepare_signals_from_data"></a>

#### Miner.prepare\_signals\_from\_data

```python
def prepare_signals_from_data(data_json_path)
```

Reads the data.json file for a hotkey, extracts all their orders,
and transforms them into a list of TradingSignal dicts for the circuits.

**Arguments**:

- `data_json_path` _str_ - Path to the data.json file


**Returns**:

- `tuple` - (padded_signals, actual_len)

<a id="proof_of_portfolio.miner.Miner.run_merkle_generator"></a>

#### Miner.run\_merkle\_generator

```python
def run_merkle_generator(signals, actual_len)
```

Runs the merkle_generator circuit and parses the witness file to get the output.

**Arguments**:

- `signals` _list_ - List of trading signals
- `actual_len` _int_ - Actual number of signals


**Returns**:

- `tuple` - (merkle_root, path_elements, path_indices) or None if failed

<a id="proof_of_portfolio.miner.Miner.generate_tree"></a>

#### Miner.generate\_tree

```python
@requires_dependencies
def generate_tree(input_json_path: str, output_path: str = None)
```

Generates a Merkle tree from a child hotkey data.json file and saves it to the specified path.

**Arguments**:

- `input_json_path` _str_ - Path to the child hotkey data.json file
- `output_path` _str, optional_ - Path where the tree.json file will be saved.
  If not provided, saves to the same directory as the input file.


**Returns**:

- `dict` - Tree data containing merkle_root, path_elements, and path_indices, or None if failed

<a id="proof_of_portfolio.miner.Miner.visualize_tree"></a>

#### Miner.visualize\_tree

```python
def visualize_tree(tree_data)
```

Visualizes the merkle tree in a user-friendly format with ASCII art.
Only shows the first "actual_len" path elements, ignoring filler paths.

**Arguments**:

- `tree_data` _dict_ - Tree data containing merkle_root, path_elements, and path_indices


**Returns**:

- `str` - A string representation of the tree with ASCII art

<a id="proof_of_portfolio.circuits.generate_inputs"></a>

# proof\_of\_portfolio.circuits.generate\_inputs

<a id="proof_of_portfolio.circuits.generate_inputs.SCALE"></a>

#### proof\_of\_portfolio.circuits.generate\_inputs.SCALE

```python
SCALE = 10_000_000
```

Same scale as used in the circuit

<a id="proof_of_portfolio.circuits.generate_inputs.load_validator_checkpoint"></a>

#### load\_validator\_checkpoint

```python
def load_validator_checkpoint(file_path: str) -> Dict[str, Any]
```

Load and parse the validator checkpoint JSON file.

<a id="proof_of_portfolio.circuits.generate_inputs.extract_checkpoint_data"></a>

#### extract\_checkpoint\_data

```python
def extract_checkpoint_data(checkpoint_data: Dict[str, Any],
                            miner_hotkey: str) -> Dict[str, Any]
```

Extract checkpoint data for a specific miner.

<a id="proof_of_portfolio.circuits.generate_inputs.extract_trading_signals"></a>

#### extract\_trading\_signals

```python
def extract_trading_signals(checkpoint_data: Dict[str, Any],
                            miner_hotkey: str) -> List[Dict[str, Any]]
```

Extract trading signals from position data for a specific miner.

<a id="proof_of_portfolio.circuits.generate_inputs.create_signals_toml"></a>

#### create\_signals\_toml

```python
def create_signals_toml(signals: List[Dict[str, Any]]) -> str
```

Create TOML content for signals to use with tree_generator.

<a id="proof_of_portfolio.circuits.generate_inputs.run_tree_generator"></a>

#### run\_tree\_generator

```python
def run_tree_generator(
    signals: List[Dict[str,
                       Any]]) -> Tuple[str, List[List[str]], List[List[str]]]
```

Run the tree_generator to create merkle tree and get proofs.

<a id="proof_of_portfolio.circuits.generate_inputs.pad_arrays"></a>

#### pad\_arrays

```python
def pad_arrays(data: Dict[str, Any], max_size: int = 200) -> Dict[str, Any]
```

Pad arrays to the maximum size expected by the circuit.

<a id="proof_of_portfolio.circuits.generate_inputs.format_2d_array_for_toml"></a>

#### format\_2d\_array\_for\_toml

```python
def format_2d_array_for_toml(arr: List[List[str]], name: str) -> str
```

Format 2D array for TOML.

<a id="proof_of_portfolio.circuits.generate_inputs.generate_prover_toml"></a>

#### generate\_prover\_toml

```python
def generate_prover_toml(
        checkpoint_file_path: str = "../validator_checkpoint.json",
        miner_hotkey: str = None) -> str
```

Generate Prover.toml content from checkpoint data.

<a id="proof_of_portfolio.circuits.generate_inputs.main"></a>

#### main

```python
def main()
```

Main function to generate and write Prover.toml.

<a id="proof_of_portfolio.min_metrics"></a>

# proof\_of\_portfolio.min\_metrics

<a id="proof_of_portfolio.min_metrics.MinMetrics"></a>

## MinMetrics Objects

```python
class MinMetrics()
```

Minimal metrics implementation that matches the proprietary trading network
validator metrics calculations exactly. Used for comparing ZK circuit outputs
against Python calculations on the same input data.

<a id="proof_of_portfolio.min_metrics.MinMetrics.weighting_distribution"></a>

#### MinMetrics.weighting\_distribution

```python
@staticmethod
def weighting_distribution(
        log_returns: Union[list[float], np.ndarray]) -> np.ndarray
```

Returns the weighting distribution that decays from max_weight to min_weight
using the configured decay rate

<a id="proof_of_portfolio.min_metrics.MinMetrics.average"></a>

#### MinMetrics.average

```python
@staticmethod
def average(log_returns: Union[list[float], np.ndarray],
            weighting=False,
            indices: Union[list[int], None] = None) -> float
```

Returns the mean of the log returns

<a id="proof_of_portfolio.min_metrics.MinMetrics.variance"></a>

#### MinMetrics.variance

```python
@staticmethod
def variance(log_returns: list[float],
             ddof: int = 1,
             weighting=False,
             indices: Union[list[int], None] = None) -> float
```

Returns the variance of the log returns

<a id="proof_of_portfolio.min_metrics.MinMetrics.ann_excess_return"></a>

#### MinMetrics.ann\_excess\_return

```python
@staticmethod
def ann_excess_return(log_returns: list[float],
                      weighting=False,
                      days_in_year: int = DAYS_IN_YEAR_CRYPTO) -> float
```

Calculates annualized excess return using mean daily log returns and mean daily 1yr risk free rate.

<a id="proof_of_portfolio.min_metrics.MinMetrics.ann_volatility"></a>

#### MinMetrics.ann\_volatility

```python
@staticmethod
def ann_volatility(log_returns: list[float],
                   ddof: int = 1,
                   weighting=False,
                   indices: list[int] = None,
                   days_in_year: int = DAYS_IN_YEAR_CRYPTO) -> float
```

Calculates annualized volatility ASSUMING DAILY OBSERVATIONS

<a id="proof_of_portfolio.min_metrics.MinMetrics.ann_downside_volatility"></a>

#### MinMetrics.ann\_downside\_volatility

```python
@staticmethod
def ann_downside_volatility(log_returns: list[float],
                            target: int = None,
                            weighting=False,
                            days_in_year: int = DAYS_IN_YEAR_CRYPTO) -> float
```

Calculates annualized downside volatility

<a id="proof_of_portfolio.min_metrics.MinMetrics.daily_max_drawdown"></a>

#### MinMetrics.daily\_max\_drawdown

```python
@staticmethod
def daily_max_drawdown(log_returns: list[float]) -> float
```

Calculates the daily maximum drawdown

<a id="proof_of_portfolio.min_metrics.MinMetrics.sharpe"></a>

#### MinMetrics.sharpe

```python
@staticmethod
def sharpe(log_returns: list[float],
           bypass_confidence: bool = False,
           weighting: bool = False,
           days_in_year: int = DAYS_IN_YEAR_CRYPTO,
           **kwargs) -> float
```

Calculates the Sharpe ratio

<a id="proof_of_portfolio.min_metrics.MinMetrics.omega"></a>

#### MinMetrics.omega

```python
@staticmethod
def omega(log_returns: list[float],
          bypass_confidence: bool = False,
          weighting: bool = False,
          **kwargs) -> float
```

Calculates the Omega ratio

<a id="proof_of_portfolio.min_metrics.MinMetrics.statistical_confidence"></a>

#### MinMetrics.statistical\_confidence

```python
@staticmethod
def statistical_confidence(log_returns: list[float],
                           bypass_confidence: bool = False,
                           **kwargs) -> float
```

Calculates statistical confidence using t-test

<a id="proof_of_portfolio.min_metrics.MinMetrics.sortino"></a>

#### MinMetrics.sortino

```python
@staticmethod
def sortino(log_returns: list[float],
            bypass_confidence: bool = False,
            weighting: bool = False,
            days_in_year: int = DAYS_IN_YEAR_CRYPTO,
            **kwargs) -> float
```

Calculates the Sortino ratio

<a id="proof_of_portfolio.analyze_data"></a>

# proof\_of\_portfolio.analyze\_data

analyse_data.py

This script takes data from data/input.json and creates a folder called 'children'
inside the data directory which contains all the trades based on unique hotkeys/users.

Each user's trades are saved to a separate JSON file named data.json in a directory
named after their hotkey (children/{hotkey}/data.json).

<a id="proof_of_portfolio.analyze_data.split_input_json"></a>

#### split\_input\_json

```python
def split_input_json(input_file_path: str = "../data/input_data.json",
                     output_dir: str = "../data/children")
```

Splits the input JSON file into separate files for each hotkey.

**Arguments**:

- `input_file_path` _str_ - Path to the input JSON file
- `output_dir` _str_ - Directory where the split files will be saved


**Returns**:

- `int` - Number of hotkeys processed

<a id="proof_of_portfolio.post_install"></a>

# proof\_of\_portfolio.post\_install

<a id="proof_of_portfolio.post_install.refresh_shell_environment"></a>

#### refresh\_shell\_environment

```python
def refresh_shell_environment()
```

Refresh shell environment by sourcing profile files

<a id="proof_of_portfolio.post_install.install_noirup"></a>

#### install\_noirup

```python
def install_noirup()
```

Install noirup if not present

<a id="proof_of_portfolio.post_install.install_nargo"></a>

#### install\_nargo

```python
def install_nargo()
```

Install nargo using noirup

<a id="proof_of_portfolio.post_install.install_bbup"></a>

#### install\_bbup

```python
def install_bbup()
```

Install bbup if not present

<a id="proof_of_portfolio.post_install.install_bb"></a>

#### install\_bb

```python
def install_bb()
```

Install bb using bbup

<a id="proof_of_portfolio.signal_processor"></a>

# proof\_of\_portfolio.signal\_processor

<a id="proof_of_portfolio.signal_processor.parse_order_string"></a>

#### parse\_order\_string

```python
def parse_order_string(order_str: str) -> Optional[Dict[str, Any]]
```

Parse order string by replacing PriceSource with dict and using eval with restricted globals

<a id="proof_of_portfolio.signal_processor.load_processed_signals"></a>

#### load\_processed\_signals

```python
def load_processed_signals(signals_path: Path) -> List[Dict[str, Any]]
```

Load and parse all processed signal files from directory

<a id="proof_of_portfolio.signal_processor.sort_signals_chronologically"></a>

#### sort\_signals\_chronologically

```python
def sort_signals_chronologically(
        signals: List[Dict[str, Any]]) -> List[Dict[str, Any]]
```

Sort signals by processing_timestamp in chronological order

<a id="proof_of_portfolio.signal_processor.extract_validator_orders"></a>

#### extract\_validator\_orders

```python
def extract_validator_orders(
        signals: List[Dict[str, Any]]) -> Dict[str, List[Dict[str, Any]]]
```

Extract orders for each validator from chronologically sorted signals

<a id="proof_of_portfolio.signal_processor.generate_validator_trees"></a>

#### generate\_validator\_trees

```python
def generate_validator_trees(signals_dir: str,
                             hotkey: Optional[str] = None,
                             output_dir: Optional[str] = None,
                             quiet: bool = False) -> Dict[str, Dict[str, Any]]
```

Generate merkle trees for all validators from processed mining signals.

**Arguments**:

- `signals_dir` - Directory containing processed signal JSON files
- `hotkey` - Optional hotkey to use for tree generation
- `output_dir` - Optional directory to save tree files
- `quiet` - Whether to suppress output messages


**Returns**:

  Dictionary mapping validator keys to tree data and metadata

<a id="proof_of_portfolio.signal_processor.get_validator_tree_hashes"></a>

#### get\_validator\_tree\_hashes

```python
def get_validator_tree_hashes(
        validator_trees: Dict[str, Dict[str, Any]]) -> Dict[str, str]
```

Extract tree hashes for each validator for verification purposes.

**Arguments**:

- `validator_trees` - Dictionary of validator tree data from generate_validator_trees


**Returns**:

  Dictionary mapping validator keys to their tree hashes

<a id="proof_of_portfolio.parsing_utils"></a>

# proof\_of\_portfolio.parsing\_utils

Shared parsing utilities for nargo output across all demos.

<a id="proof_of_portfolio.parsing_utils.parse_single_field_output"></a>

#### parse\_single\_field\_output

```python
def parse_single_field_output(output)
```

Parses nargo output that contains a single field value.
Returns the integer value, or None if no field found.

<a id="proof_of_portfolio.parsing_utils.field_to_signed_int"></a>

#### field\_to\_signed\_int

```python
def field_to_signed_int(field_str)
```

Convert a field string to a signed integer, handling two's complement.

<a id="proof_of_portfolio.parsing_utils.parse_demo_output"></a>

#### parse\_demo\_output

```python
def parse_demo_output(output, scale=10_000_000, no_confidence_value=-100)
```

Standardized parsing for demo output.

**Arguments**:

- `output` - Raw stdout
- `scale` - Scale factor used in the circuit (default 10M)
- `no_confidence_value` - Value indicating no confidence result


**Returns**:

  Float value scaled appropriately, or the no_confidence_value as-is

<a id="proof_of_portfolio.parsing_utils.parse_nargo_struct_output"></a>

#### parse\_nargo\_struct\_output

```python
def parse_nargo_struct_output(output)
```

Parses the raw output of a nargo execute command that returns a struct.

<a id="proof_of_portfolio.parsing_utils.parse_nested_arrays"></a>

#### parse\_nested\_arrays

```python
def parse_nested_arrays(section)
```

Helper function to parse nested array structures like [[...], [...]]

<a id="proof_of_portfolio.main"></a>

# proof\_of\_portfolio.main

Proof of Portfolio (pop) CLI

A command-line interface for the Proof of Portfolio system.

This CLI provides commands for both Miners and Validators.

Miner Commands:
  - generate-tree: Generate a Merkle tree for a miner's portfolio data.

Validator Commands:
  - validate: Validate a single miner's data and generate their Merkle tree.
  - validate-all: Validate all miners' data from an input file or directory.
  - analyse-data: Pre-process a large data file, splitting it by miner.

Utility Commands:
  - generate-test-data: Create a randomized test data file for validation.
  - save-tree: Save a generated Merkle tree to a specified output file.
  - demo: Run demonstration scripts for various system components.

<a id="proof_of_portfolio.main.generate_tree"></a>

#### generate\_tree

```python
def generate_tree(args)
```

Generate a merkle tree for a miner using their data.json file.

**Arguments**:

- `args` - Command line arguments containing the data_file path, hotkey, and output_path

<a id="proof_of_portfolio.main.validate_miner"></a>

#### validate\_miner

```python
def validate_miner(args)
```

Generate a merkle tree for a miner as a validator.

**Arguments**:

- `args` - Command line arguments containing the data_file path

<a id="proof_of_portfolio.main.validate_all_miners"></a>

#### validate\_all\_miners

```python
def validate_all_miners(args)
```

Generate merkle trees for all miners in a directory.

**Arguments**:

- `args` - Command line arguments containing the input_path path

<a id="proof_of_portfolio.main.analyse_data"></a>

#### analyse\_data

```python
def analyse_data(args)
```

Analyze input data and split it into separate files for each hotkey.

**Arguments**:

- `args` - Command line arguments containing the path to the input JSON file

<a id="proof_of_portfolio.main.save_tree"></a>

#### save\_tree

```python
def save_tree(args)
```

Save a merkle tree from a tree.json file or a hotkey directory to a specified output path.

**Arguments**:

- `args` - Command line arguments containing the path to the tree.json file or hotkey directory
  and the output path

<a id="proof_of_portfolio.main.print_header"></a>

#### print\_header

```python
def print_header()
```

Prints the ASCII art header for the CLI.

<a id="proof_of_portfolio.main.check_dependencies"></a>

#### check\_dependencies

```python
def check_dependencies()
```

Check if required dependencies (bb, nargo) are available.
If not, install them automatically.

<a id="proof_of_portfolio.main.main"></a>

#### main

```python
def main()
```

Main entry point for the CLI.

<a id="proof_of_portfolio.demos.generate_input_data"></a>

# proof\_of\_portfolio.demos.generate\_input\_data

<a id="proof_of_portfolio.demos.generate_input_data.generate_random_data"></a>

#### generate\_random\_data

```python
def generate_random_data(num_miners=10,
                         num_cps=200,
                         num_positions=10,
                         num_orders=5)
```

Generates a randomized dataset which would typically be saved as the validator_checkpoint.json file.

<a id="proof_of_portfolio.demos.generate_input_data.main"></a>

#### main

```python
def main(args)
```

Main function to generate the randomized data and save it to a file.

<a id="proof_of_portfolio.demos.main"></a>

# proof\_of\_portfolio.demos.main

<a id="proof_of_portfolio.demos.main.main"></a>

#### main

```python
def main(args)
```

Demo main function - loads data from file and calls core proof generation logic.

<a id="proof_of_portfolio.proof_generator"></a>

# proof\_of\_portfolio.proof\_generator

<a id="proof_of_portfolio.proof_generator.SCALE"></a>

#### proof\_of\_portfolio.proof\_generator.SCALE

```python
SCALE = 10**8
```

Base scaling factor (10^8) - used for all ratio outputs

<a id="proof_of_portfolio.proof_generator.get_attr"></a>

#### get\_attr

```python
def get_attr(obj, attr)
```

Get attribute from object or dictionary

<a id="proof_of_portfolio.proof_generator.scale_to_int"></a>

#### scale\_to\_int

```python
def scale_to_int(value)
```

Convert float to scaled integer

<a id="proof_of_portfolio.proof_generator.scale_from_int"></a>

#### scale\_from\_int

```python
def scale_from_int(value)
```

Convert scaled integer back to float

<a id="proof_of_portfolio.proof_generator.upload_proof"></a>

#### upload\_proof

```python
def upload_proof(proof_hex, public_inputs_hex, wallet, testnet=True)
```

Upload proof to the API endpoint.

**Arguments**:

- `proof_hex` - Proof as hex string
- `public_inputs_hex` - Public inputs as hex string
- `wallet` - Bittensor wallet for signing
- `testnet` - Whether this is a testnet proof


**Returns**:

  API response dictionary or None if failed

<a id="proof_of_portfolio.proof_generator.save_zk_results"></a>

#### save\_zk\_results

```python
def save_zk_results(results, miner_hotkey)
```

Save ZK proof results to disk in ~/.pop/ directory.

**Arguments**:

- `results` - The ZK results dictionary to save
- `miner_hotkey` - The miner's hotkey for filename

<a id="proof_of_portfolio.proof_generator.get_latest_merkle_root_for_miner"></a>

#### get\_latest\_merkle\_root\_for\_miner

```python
def get_latest_merkle_root_for_miner(hotkey)
```

Get the latest merkle root for a specific miner.

**Arguments**:

- `hotkey` - The miner's hotkey


**Returns**:

  dict with signals and returns merkle roots, or None if not found

<a id="proof_of_portfolio.proof_generator.get_all_results_for_miner"></a>

#### get\_all\_results\_for\_miner

```python
def get_all_results_for_miner(hotkey)
```

Get all ZK results for a specific miner.

**Arguments**:

- `hotkey` - The miner's hotkey


**Returns**:

  list of result dictionaries sorted by timestamp (newest first)

<a id="proof_of_portfolio.verifier"></a>

# proof\_of\_portfolio.verifier

<a id="proof_of_portfolio.verifier.ensure_bb_installed"></a>

#### ensure\_bb\_installed

```python
def ensure_bb_installed()
```

Ensure bb is installed before verification.

<a id="proof_of_portfolio.verifier.verify"></a>

#### verify

```python
def verify(proof_hex, public_inputs_hex)
```

Verify a zero-knowledge proof using hex string data.

**Arguments**:

- `proof_hex` _str_ - Hex string of proof data
- `public_inputs_hex` _str_ - Hex string of public inputs data


**Returns**:

- `bool` - True if verification succeeds, False otherwise

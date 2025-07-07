use dep::std;

// Globals
pub global MERKLE_DEPTH: u32 = 8;
pub global MAX_RETURNS: u32 = 256;
pub global MAX_SIGNALS: u32 = 256;

// Define the structure of a single trading signal for hashing.
// This must be kept in sync with any other definitions.
pub struct TradingSignal {
    pub trade_pair_id: Field,
    pub order_type: i8,
    pub leverage: u64,
    pub timestamp: u64,
}

// Hashes a single 64-bit log return into a Field element.
pub fn hash_return(log_return: i64) -> Field {
    std::hash::pedersen_hash([log_return as Field])
}

// Hashes a TradingSignal struct into a Field element.
pub fn hash_signal(signal: TradingSignal) -> Field {
    std::hash::pedersen_hash([
        signal.trade_pair_id,
        signal.order_type as Field,
        signal.leverage as Field,
        signal.timestamp as Field,
    ])
}

// Verifies a merkle inclusion proof for a given leaf
pub fn merkle_inclusion_check(
    leaf: Field,
    root: Field,
    path_elements: [Field; MERKLE_DEPTH],
    path_indices: [Field; MERKLE_DEPTH],
) -> bool {
    let mut current_hash = leaf;

    for i in 0..MERKLE_DEPTH {
        let path_element = path_elements[i];
        let path_index = path_indices[i];

        // If path_index is 0, current_hash is left child, path_element is right
        // If path_index is 1, current_hash is right child, path_element is left
        let left = if path_index == 0 {
            current_hash
        } else {
            path_element
        };
        let right = if path_index == 0 {
            path_element
        } else {
            current_hash
        };

        current_hash = std::hash::pedersen_hash([left, right]);
    }

    current_hash == root
}

pub fn build_merkle_root(leaves: [Field; MAX_RETURNS], num_leaves: u32) -> Field {
    let mut nodes = leaves;
    let mut current_num_leaves = num_leaves;

    // The number of levels to compute is log2(MAX_RETURNS), which is 8
    for _ in 0..8 {
        let mut next_level_nodes = [0; MAX_RETURNS];

        for i in 0..(MAX_RETURNS / 2) {
            if (i * 2) < current_num_leaves {
                let left = nodes[i * 2];
                // Handle odd number of leaves for this level
                let right = if (i * 2 + 1) < current_num_leaves {
                    nodes[i * 2 + 1]
                } else {
                    left
                };
                let mut hash_inputs = [left, right];
                next_level_nodes[i] = std::hash::pedersen_hash(hash_inputs);
            }
        }
        nodes = next_level_nodes;

        let next_num_leaves = (current_num_leaves + 1) / 2;
        current_num_leaves = if current_num_leaves <= 1 {
            current_num_leaves
        } else {
            next_num_leaves
        };
    }

    if num_leaves == 0 {
        0
    } else {
        nodes[0]
    }
}

// Builds a Merkle root directly from an array of TradingSignal structs.
pub fn build_merkle_root_from_signals(
    signals: [TradingSignal; MAX_RETURNS],
    n_signals: u32,
) -> Field {
    let mut leaves = [0; MAX_RETURNS];
    for i in 0..MAX_RETURNS {
        if (i as u32) < n_signals {
            leaves[i] = hash_signal(signals[i]);
        } else {
            // Use a default zero hash for padding to prevent information leakage.
            leaves[i] = 0;
        }
    }
    build_merkle_root(leaves, n_signals)
}

// Obsolete merkle_inclusion_check and tests for TradingSignal are removed.

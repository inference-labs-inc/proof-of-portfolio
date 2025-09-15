global ARRAY_SIZE: u32 = 1024;
global SCALE: i64 = 10000000;

fn min_array(arr: [i64; ARRAY_SIZE], n_elements: u32) -> i64 {
    let mut min_val = SCALE; // Start with maximum possible value (1.0 scaled)
    for i in 0..ARRAY_SIZE {
        if (i as u32) < n_elements {
            if arr[i] < min_val {
                min_val = arr[i];
            }
        }
    }
    min_val
}

fn clip_value(value: i64, min_val: i64, max_val: i64) -> i64 {
    if value < min_val {
        min_val
    } else if value > max_val {
        max_val
    } else {
        value
    }
}

// Convert drawdown percentage to scaled integer
fn drawdown_to_percentage(drawdown_decimal: i64) -> i64 {
    let mut result = 0;

    if drawdown_decimal >= SCALE {
        result = 0;
    } else if drawdown_decimal <= 0 {
        result = 100 * SCALE / 100; // 100% scaled
    } else {
        // Calculate (1 - drawdown_decimal) * 100
        // But scale result properly: percentage should be scaled by SCALE/100
        let percentage_unscaled = (SCALE - drawdown_decimal) * 100 / SCALE;
        result = clip_value(percentage_unscaled, 0, 100 * SCALE / 100);
    }

    result
}

fn instantaneous_max_drawdown(mdd_values: [i64; ARRAY_SIZE], n_checkpoints: u32) -> i64 {
    let mut result = 0;

    if n_checkpoints == 0 {
        result = 0;
    } else {
        // Find minimum MDD value (worst drawdown)
        let effective_drawdown = min_array(mdd_values, n_checkpoints);
        // Clip between 0 and 1.0 (scaled)
        result = clip_value(effective_drawdown, 0, SCALE);
    }

    result
}

fn is_beyond_max_drawdown(
    mdd_values: [i64; ARRAY_SIZE],
    n_checkpoints: u32,
    max_drawdown_threshold: i64,
) -> (bool, i64) {
    let mut exceeds_threshold = false;
    let mut recorded_drawdown_percentage = 0;

    if n_checkpoints == 0 {
        exceeds_threshold = false;
        recorded_drawdown_percentage = 0;
    } else {
        let max_drawdown = instantaneous_max_drawdown(mdd_values, n_checkpoints);
        recorded_drawdown_percentage = drawdown_to_percentage(max_drawdown);

        // Check if drawdown percentage >= threshold percentage
        exceeds_threshold = recorded_drawdown_percentage >= max_drawdown_threshold;
    }

    (exceeds_threshold, recorded_drawdown_percentage)
}

fn main(
    hotkey: pub str<48>, // Public hotkey identifier (SS58 addresses are 48 chars)
    mdd_values: [i64; ARRAY_SIZE], // Private ledger values
    n_checkpoints: u32, // Private
    max_drawdown_threshold: pub i64, // Public threshold
) -> pub (bool, i64) {
    is_beyond_max_drawdown(mdd_values, n_checkpoints, max_drawdown_threshold)
}

#[test]
fn test_no_drawdown() {
    // Test: No drawdown
    // Expected: exceeds_threshold=false, drawdown_percentage=0.0
    let hotkey = "5FHneW46xGXgs5mUiveU4sbTyGBzmstUspZC92UhjJM694ty"; // Mock SS58 hotkey
    let mut mdd_values = [0; ARRAY_SIZE];
    mdd_values[0] = 10000000;
    mdd_values[1] = 10000000;
    mdd_values[2] = 10000000;
    mdd_values[3] = 10000000;
    let n_checkpoints = 4;
    let max_drawdown_threshold = 10;

    let (exceeds_threshold, drawdown_percentage) =
        main(hotkey, mdd_values, n_checkpoints, max_drawdown_threshold);

    assert(exceeds_threshold == false);
    assert(drawdown_percentage == 0);
}

#[test]
fn test_small_drawdown_5_percent() {
    // Test: Small drawdown (5%)
    // Expected: exceeds_threshold=false, drawdown_percentage=5.0
    let hotkey = "5FLSigC9HGRKVhB9FiEo4Y3koPsNmBmLJbpXg2mp1hXcS59Y"; // Mock SS58 hotkey
    let mut mdd_values = [0; ARRAY_SIZE];
    mdd_values[0] = 10000000;
    mdd_values[1] = 9800000;
    mdd_values[2] = 9500000;
    mdd_values[3] = 9700000;
    let n_checkpoints = 4;
    let max_drawdown_threshold = 10;

    let (exceeds_threshold, drawdown_percentage) =
        main(hotkey, mdd_values, n_checkpoints, max_drawdown_threshold);

    assert(exceeds_threshold == false);
    // 5% scaled = 5
    assert(drawdown_percentage == 5);
}

#[test]
fn test_at_threshold_10_percent() {
    // Test: At threshold (10%)
    // Expected: exceeds_threshold=true, drawdown_percentage=10.0
    let hotkey = "5DAAnrj7VHTznn2AWBemMuyBwZWs6FNFjdyVXUeYum3PTXFy"; // Mock SS58 hotkey
    let mut mdd_values = [0; ARRAY_SIZE];
    mdd_values[0] = 10000000;
    mdd_values[1] = 9500000;
    mdd_values[2] = 9000000;
    mdd_values[3] = 9200000;
    let n_checkpoints = 4;
    let max_drawdown_threshold = 10;

    let (exceeds_threshold, drawdown_percentage) =
        main(hotkey, mdd_values, n_checkpoints, max_drawdown_threshold);

    assert(exceeds_threshold == true);
    // 10% scaled = 10
    assert(drawdown_percentage == 10);
}

#[test]
fn test_above_threshold_15_percent() {
    // Test: Above threshold (15%)
    // Expected: exceeds_threshold=true, drawdown_percentage=15.0
    let hotkey = "5HGjWAeFDfFCWPsjFQdVV2Msvz2XtMktvgocEZcCj68kUMaw"; // Mock SS58 hotkey
    let mut mdd_values = [0; ARRAY_SIZE];
    mdd_values[0] = 10000000;
    mdd_values[1] = 9000000;
    mdd_values[2] = 8500000;
    mdd_values[3] = 8800000;
    let n_checkpoints = 4;
    let max_drawdown_threshold = 10;

    let (exceeds_threshold, drawdown_percentage) =
        main(hotkey, mdd_values, n_checkpoints, max_drawdown_threshold);

    assert(exceeds_threshold == true);
    // 15% scaled = 15
    assert(drawdown_percentage == 15);
}

#[test]
fn test_empty_ledger() {
    // Test: Empty ledger
    // Expected: exceeds_threshold=false, drawdown_percentage=0
    let hotkey = "5CiPPseXPECbkjWCa6MnjNokrgYjMqmKndv2rSnekmSK2DjL"; // Mock SS58 hotkey
    let mdd_values = [0; ARRAY_SIZE];
    let n_checkpoints = 0;
    let max_drawdown_threshold = 10;

    let (exceeds_threshold, drawdown_percentage) =
        main(hotkey, mdd_values, n_checkpoints, max_drawdown_threshold);

    assert(exceeds_threshold == false);
    assert(drawdown_percentage == 0);
}

#[test]
fn test_single_checkpoint_above_threshold() {
    // Test: Single checkpoint with 12% drawdown
    // Expected: exceeds_threshold=true, drawdown_percentage=12.0
    let hotkey = "5GrwvaEF5zXb26Fz9rcQpDWS57CtERHpNehXCPcNoHGKutQY"; // Mock SS58 hotkey
    let mut mdd_values = [0; ARRAY_SIZE];
    mdd_values[0] = 8800000; // 0.88 scaled = 8800000
    let n_checkpoints = 1;
    let max_drawdown_threshold = 10;

    let (exceeds_threshold, drawdown_percentage) =
        main(hotkey, mdd_values, n_checkpoints, max_drawdown_threshold);

    assert(exceeds_threshold == true);
    // 12% scaled = 12
    assert(drawdown_percentage == 12);
}

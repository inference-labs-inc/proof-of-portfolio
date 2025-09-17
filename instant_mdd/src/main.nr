global ARRAY_SIZE: u32 = 1024;
global SCALE: i64 = 10000000;

fn min_array(arr: [i64; ARRAY_SIZE], n_elements: u32) -> i64 {
    let mut min_val = SCALE;
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

fn drawdown_to_percentage(drawdown_decimal: i64) -> i64 {
    let mut result = 0;

    if drawdown_decimal >= SCALE {
        result = 0;
    } else if drawdown_decimal <= 0 {
        result = 100 * SCALE / 100;
    } else {
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
        let effective_drawdown = min_array(mdd_values, n_checkpoints);

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

        exceeds_threshold = recorded_drawdown_percentage >= max_drawdown_threshold;
    }

    (exceeds_threshold, recorded_drawdown_percentage)
}

fn main(
    hotkey: pub str<48>,
    mdd_values: [i64; ARRAY_SIZE],
    n_checkpoints: u32,
    max_drawdown_threshold: pub i64,
) -> pub (bool, i64) {
    is_beyond_max_drawdown(mdd_values, n_checkpoints, max_drawdown_threshold)
}

#[test]
fn test_no_drawdown() {
    let hotkey = "5FHneW46xGXgs5mUiveU4sbTyGBzmstUspZC92UhjJM694ty";
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
    let hotkey = "5FLSigC9HGRKVhB9FiEo4Y3koPsNmBmLJbpXg2mp1hXcS59Y";
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

    assert(drawdown_percentage == 5);
}

#[test]
fn test_at_threshold_10_percent() {
    let hotkey = "5DAAnrj7VHTznn2AWBemMuyBwZWs6FNFjdyVXUeYum3PTXFy";
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

    assert(drawdown_percentage == 10);
}

#[test]
fn test_above_threshold_15_percent() {
    let hotkey = "5HGjWAeFDfFCWPsjFQdVV2Msvz2XtMktvgocEZcCj68kUMaw";
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

    assert(drawdown_percentage == 15);
}

#[test]
fn test_empty_ledger() {
    let hotkey = "5CiPPseXPECbkjWCa6MnjNokrgYjMqmKndv2rSnekmSK2DjL";
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
    let hotkey = "5GrwvaEF5zXb26Fz9rcQpDWS57CtERHpNehXCPcNoHGKutQY";
    let mut mdd_values = [0; ARRAY_SIZE];
    mdd_values[0] = 8800000;
    let n_checkpoints = 1;
    let max_drawdown_threshold = 10;

    let (exceeds_threshold, drawdown_percentage) =
        main(hotkey, mdd_values, n_checkpoints, max_drawdown_threshold);

    assert(exceeds_threshold == true);

    assert(drawdown_percentage == 12);
}

#[test]
fn test_no_drawdown_case_1() {
    let hotkey = "5CiPPseXPECbkjWCa6MnjNokrgYjMqmKndv2rSnekmSK2DjL";
    let mut mdd_values = [0; ARRAY_SIZE];
    mdd_values[0] = 10000000;
    mdd_values[1] = 10000000;
    mdd_values[2] = 10000000;
    mdd_values[3] = 10000000;
    mdd_values[4] = 10000000;
    mdd_values[5] = 10000000;
    mdd_values[6] = 10000000;
    mdd_values[7] = 10000000;
    mdd_values[8] = 10000000;
    mdd_values[9] = 10000000;
    let n_checkpoints = 10;
    let max_drawdown_threshold = 10;

    let (exceeds_threshold, drawdown_percentage) =
        main(hotkey, mdd_values, n_checkpoints, max_drawdown_threshold);

    assert(exceeds_threshold == false);
    assert(drawdown_percentage == 0);
}

#[test]
fn test_small_drawdown_case_2() {
    let hotkey = "5FLSigC9HGRKVhB9FiEo4Y3koPsNmBmLJbpXg2mp1hXcS59Y";
    let mut mdd_values = [0; ARRAY_SIZE];
    mdd_values[0] = 10000000;
    mdd_values[1] = 9916871;
    mdd_values[2] = 9833743;
    mdd_values[3] = 9750615;
    mdd_values[4] = 9667487;
    mdd_values[5] = 9584358;
    mdd_values[6] = 9501230;
    mdd_values[7] = 9418102;
    mdd_values[8] = 9459666;
    mdd_values[9] = 9501230;
    mdd_values[10] = 9542794;
    mdd_values[11] = 9584358;
    mdd_values[12] = 9625923;
    mdd_values[13] = 9667487;
    mdd_values[14] = 9709051;
    let n_checkpoints = 15;
    let max_drawdown_threshold = 10;

    let (exceeds_threshold, drawdown_percentage) =
        main(hotkey, mdd_values, n_checkpoints, max_drawdown_threshold);

    assert(exceeds_threshold == false);
    assert(drawdown_percentage == 5);
}

#[test]
fn test_at_threshold_case_3() {
    let hotkey = "5HGjWAeFDfFCWPsjFQdVV2Msvz2XtMktvgocEZcCj68kUMaw";
    let mut mdd_values = [0; ARRAY_SIZE];
    mdd_values[0] = 9562804;
    mdd_values[1] = 9824468;
    mdd_values[2] = 9562932;
    mdd_values[3] = 9940822;
    mdd_values[4] = 9376592;
    mdd_values[5] = 9337430;
    mdd_values[6] = 8999000;
    mdd_values[7] = 9391450;
    mdd_values[8] = 9389312;
    mdd_values[9] = 9701904;
    mdd_values[10] = 9212191;
    mdd_values[11] = 9236958;
    mdd_values[12] = 9585862;
    let n_checkpoints = 13;
    let max_drawdown_threshold = 10;

    let (exceeds_threshold, drawdown_percentage) =
        main(hotkey, mdd_values, n_checkpoints, max_drawdown_threshold);

    assert(exceeds_threshold == true);
    assert(drawdown_percentage == 10);
}

#[test]
fn test_above_threshold_case_4() {
    let hotkey = "5FLSigC9HGRKVhB9FiEo4Y3koPsNmBmLJbpXg2mp1hXcS59Y";
    let mut mdd_values = [0; ARRAY_SIZE];
    mdd_values[0] = 9975804;
    mdd_values[1] = 9866818;
    mdd_values[2] = 9823327;
    mdd_values[3] = 9764019;
    mdd_values[4] = 9552855;
    mdd_values[5] = 9685798;
    mdd_values[6] = 9634295;
    mdd_values[7] = 8525316;
    mdd_values[8] = 9701443;
    mdd_values[9] = 9659777;
    mdd_values[10] = 9636628;
    mdd_values[11] = 9719018;
    mdd_values[12] = 9928452;
    mdd_values[13] = 9819323;
    let n_checkpoints = 14;
    let max_drawdown_threshold = 10;

    let (exceeds_threshold, drawdown_percentage) =
        main(hotkey, mdd_values, n_checkpoints, max_drawdown_threshold);

    assert(exceeds_threshold == true);
    assert(drawdown_percentage == 14);
}

#[test]
fn test_extreme_drawdown_case_5() {
    let hotkey = "5FHneW46xGXgs5mUiveU4sbTyGBzmstUspZC92UhjJM694ty";
    let mut mdd_values = [0; ARRAY_SIZE];
    mdd_values[0] = 9779485;
    mdd_values[1] = 9004520;
    mdd_values[2] = 9556620;
    mdd_values[3] = 9244946;
    mdd_values[4] = 9781038;
    mdd_values[5] = 9945216;
    mdd_values[6] = 9480322;
    mdd_values[7] = 6194241;
    mdd_values[8] = 9272647;
    mdd_values[9] = 9638097;
    mdd_values[10] = 9781863;
    mdd_values[11] = 9522053;
    mdd_values[12] = 9666371;
    mdd_values[13] = 9672193;
    let n_checkpoints = 14;
    let max_drawdown_threshold = 10;

    let (exceeds_threshold, drawdown_percentage) =
        main(hotkey, mdd_values, n_checkpoints, max_drawdown_threshold);

    assert(exceeds_threshold == true);
    assert(drawdown_percentage == 38);
}

unconstrained fn compute_sqrt(n: u64) -> u64 {
    // Attempt naive guesses to save on resources. If none pass we'll have to iterate through :(
    if n <= 1 {
        n
    } else if n <= 3 {
        1
    } else if n <= 8 {
        2
    } else if n <= 15 {
        3
    } else {
        let mut x = if n < 100 {
            n / 3
        } else if n < 10000 {
            n / 10
        } else {
            n / 100
        };

        if x == 0 {
            x = 1;
        }

        let mut prev = 0;
        for _ in 0..15 {
            if x != prev {
                if x > 0 {
                    prev = x;
                    x = (x + n / x) / 2;
                }
            }
        }

        x
    }
}

// Essentially an oracle from the unproven environment into the proven env.
// This is fine, because to prove square root, at least in unsigned integer space, we just need to prove two constraints:
// 1. The square result is less than or equal to the input
// 2. The square result + 1 is greater than the input

pub fn sqrt(n: u64) -> u64 {
    // Safety: this is constrained for floored int div properly. The computation to get to the result doesn't need to be constrained.
    let sqrt_result = unsafe { compute_sqrt(n) };
    assert(sqrt_result * sqrt_result <= n);
    assert((sqrt_result + 1) * (sqrt_result + 1) > n);
    sqrt_result
}

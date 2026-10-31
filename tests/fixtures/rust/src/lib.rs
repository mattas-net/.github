//! Self-test fixture for mattas-net/.github rust-ci.yml.

/// Returns the sum of two integers.
pub fn add(a: i64, b: i64) -> i64 {
    a + b
}

#[cfg(test)]
mod tests {
    use super::add;

    #[test]
    fn adds() {
        assert_eq!(add(2, 3), 5);
    }
}

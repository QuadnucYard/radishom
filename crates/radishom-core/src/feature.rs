use std::collections::{HashMap, HashSet, VecDeque};

use ecow::EcoString;

/// Resolves all dependent features for a given array of enabled features.
///
/// This function performs a breadth-first traversal of feature dependencies
/// to build a complete list of features that should be enabled.
///
/// # Arguments
/// - `features`: A mapping of feature names to their dependencies
/// - `enabled_features`: Initial list of explicitly enabled features
///
/// # Returns
/// A vector containing all enabled features including dependencies
///
/// # Example
/// ```
/// use std::collections::HashMap;
///
/// let mut features = HashMap::new();
/// features.insert("a".into(), vec!["b".into(), "c".into()]);
/// features.insert("b".into(), vec!["d".into()]);
///
/// let enabled = vec!["a".into()];
/// let result = resolve_enabled_features(&features, &enabled);
/// // Returns ["a", "b", "c", "d"] (order may vary)
/// ```
pub fn resolve_enabled_features(
    features: &HashMap<EcoString, Vec<EcoString>>,
    enabled_features: &[EcoString],
) -> HashSet<EcoString> {
    let mut all_enabled_features = HashSet::new();
    let mut work_list = VecDeque::new();

    // Initialize with explicitly enabled features
    for feature in enabled_features {
        if all_enabled_features.insert(feature.clone()) {
            work_list.push_back(feature.clone());
        }
    }

    // Process dependencies
    while let Some(current) = work_list.pop_front() {
        if let Some(dependencies) = features.get(&current) {
            for dep in dependencies {
                if all_enabled_features.insert(dep.clone()) {
                    work_list.push_back(dep.clone());
                }
            }
        }
    }

    all_enabled_features
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_resolve_enabled_features() {
        let mut features = HashMap::new();
        features.insert("a".into(), vec!["b".into(), "c".into()]);
        features.insert("b".into(), vec!["d".into()]);

        let enabled = vec!["a".into()];
        let mut result = resolve_enabled_features(&features, &enabled)
            .into_iter()
            .collect::<Vec<_>>();
        result.sort(); // For deterministic testing

        let expected: Vec<EcoString> = vec!["a".into(), "b".into(), "c".into(), "d".into()];

        assert_eq!(result, expected);
    }
}

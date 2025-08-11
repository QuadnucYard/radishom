use std::collections::{BTreeMap, BTreeSet, VecDeque};

use ecow::EcoString;
use serde_derive::{Deserialize, Serialize};

pub type FeatureVec = Vec<EcoString>;
pub type FeatureSet = BTreeSet<EcoString>;
pub type FeatureMap = BTreeMap<EcoString, Vec<EcoString>>;

#[derive(Clone, Serialize, Deserialize)]
pub struct FeatureCondition {
    pub required: Option<EcoString>,
    pub excluded: Option<EcoString>,
}

impl FeatureCondition {
    pub fn is_enabled_by(&self, enabled_features: &FeatureSet) -> bool {
        !self.is_disabled_by(enabled_features)
    }

    pub fn is_disabled_by(&self, enabled_features: &FeatureSet) -> bool {
        self.required
            .as_ref()
            .is_some_and(|feat| !enabled_features.contains(feat))
            || self
                .excluded
                .as_ref()
                .is_some_and(|feat| enabled_features.contains(feat))
    }
}

pub fn merge_features<T: Clone>(a: &[T], b: &[T]) -> Vec<T> {
    let mut res = Vec::with_capacity(a.len() + b.len());
    res.extend_from_slice(a);
    res.extend_from_slice(b);
    res
}

pub fn resolve_all_features(features: &FeatureMap) -> FeatureSet {
    features.values().flatten().cloned().collect()
}

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
    features: &FeatureMap,
    enabled_features: &[EcoString],
) -> FeatureSet {
    let mut all_enabled_features = BTreeSet::new();
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
        let mut features = BTreeMap::new();
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

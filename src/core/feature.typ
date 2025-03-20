
/// Resolves all dependent features for a given array of enabled features.
///
/// This function performs a depth-first traversal of feature dependencies
/// to build a complete list of features that should be enabled.
///
/// *Example:*
/// ```example
/// #let features = (
///   "a": ("b", "c"),
///   "b": ("d",),
/// )
/// #let enabled = ("a",)
/// #resolve-enabled-features(features, enabled)
/// // Returns ("a", "b", "c", "d")
/// ```
///
/// - features (dictionary): A mapping of feature names to their dependencies.
/// - enabled-features (array): Initial list of explicitly enabled features.
///
/// -> array
#let resolve-enabled-features(features, enabled-features) = {
  let all-enabled-features = enabled-features
  let work-list = enabled-features
  while work-list.len() > 0 {
    let current = work-list.pop()
    if current in features {
      for dep in features.at(current) {
        if not all-enabled-features.contains(dep) {
          all-enabled-features.push(dep)
          work-list.push(dep)
        }
      }
    }
  }
  return all-enabled-features
}

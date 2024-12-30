
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

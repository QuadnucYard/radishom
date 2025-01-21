#let lerp(a, b, r) = {
  a + (b - a) * r
}

#let make-array(a) = {
  if a == none { () } else if type(a) == array { a } else { (a,) }
}

#let min-index(a) = {
  if a.len() == 0 {
    return -1
  }
  let k = 0
  for (i, x) in a.enumerate() {
    if x < a.at(k) {
      k = i
    }
  }
  return k
}

#let pick-once-elements(a) = {
  a = a.sorted()
  let res = ()
  let len = a.len()
  let i = 0
  while i < len {
    let j = i
    while j < len and a.at(j) == a.at(i) {
      j += 1
    }
    if j == i + 1 {
      res.push(a.at(i))
    }
    i = j
  }
  return res
}

/// Get a suitable rotation of the transfer marker for the given station.
#let get-preferred-angle(angles) = {
  let angles = for angle in angles {
    if angle <= -90deg { angle += 180deg }
    if angle > 90deg { angle -= 180deg }
    (angle,)
  }
  return if angles.dedup().len() == 1 {
    // parallel case
    angles.at(0) + 90deg
  } else if angles.contains(0deg) {
    // prefer horizontal
    0deg
  } else if angles.contains(90deg) {
    90deg
  } else {
    // along the direction of the first line
    angles.at(0)
  }
}

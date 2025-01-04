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

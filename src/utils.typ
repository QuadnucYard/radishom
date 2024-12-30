#let lerp(a, b, r) = {
  a + (b - a) * r
}

#let make-array(a) = {
  if a == none { () } else if type(a) == array { a } else { (a,) }
}

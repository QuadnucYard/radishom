
/// Add two vectors.
///
/// - v1 (vec2):
/// - v2 (vec2):
/// -> vec2
#let add(v1, v2) = {
  let (x1, y1) = v1
  let (x2, y2) = v2
  (x1 + x2, y1 + y2)
}

/// Calculate the average of vectors.
///
/// - vectors (array):
/// -> vec2
#let average(vectors) = {
  let (x, y) = (0, 0)
  let cnt = 0
  for (x1, y1) in vectors {
    x += x1
    y += y1
    cnt += 1
  }
  if cnt > 0 {
    x /= cnt
    y /= cnt
  }
  return (x, y)
}

/// (Copied from `cetz.intersection`)
///
/// Checks for a line-line intersection between the given points and returns its position, otherwise {{none}}.
///
/// - a (vec2): Line 1 point 1
/// - b (vec2): Line 1 point 2
/// - c (vec2): Line 2 point 1
/// - d (vec2): Line 2 point 2
/// - ray (bool): When `true`, intersections will be found for the whole line instead of inbetween the given points.
/// -> vec2, none
#let intersect-line-line(a, b, c, d, ray: false) = {
  let lli8(x1, y1, x2, y2, x3, y3, x4, y4) = {
    let nx = (x1 * y2 - y1 * x2) * (x3 - x4) - (x1 - x2) * (x3 * y4 - y3 * x4)
    let ny = (x1 * y2 - y1 * x2) * (y3 - y4) - (y1 - y2) * (x3 * y4 - y3 * x4)
    let d = (x1 - x2) * (y3 - y4) - (y1 - y2) * (x3 - x4)
    if d == 0 {
      return none
    }
    return (nx / d, ny / d)
  }
  let pt = lli8(a.at(0), a.at(1), b.at(0), b.at(1), c.at(0), c.at(1), d.at(0), d.at(1))
  if pt != none {
    let on-line(pt, a, b) = {
      let (x, y) = pt
      let epsilon = 1e-6
      let mx = calc.min(a.at(0), b.at(0)) - epsilon
      let my = calc.min(a.at(1), b.at(1)) - epsilon
      let Mx = calc.max(a.at(0), b.at(0)) + epsilon
      let My = calc.max(a.at(1), b.at(1)) + epsilon
      return mx <= x and Mx >= x and my <= y and My >= y
    }
    if ray or (on-line(pt, a, b) and on-line(pt, c, d)) {
      return pt
    }
  }
}

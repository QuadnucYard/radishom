#import "dir.typ": dirs
#import "utils.typ": min-index


#let _anchors = (dirs.W, dirs.SW, dirs.S, dirs.NW, dirs.E, dirs.NE, dirs.N, dirs.NW)
#let _anchor-orders = (0, 2, 1, 3)

/// Find a best anchor placement with least punishment.
#let get-best-anchor-tr(tr-ctx) = {
  let punishment = (0, 1) * 4 // for 0deg, 45deg, ..., 315deg; prefer ortho
  for (pos, seg-idx, segments) in tr-ctx {
    let seg = segments.at(seg-idx)

    // collect ray targets
    let targets = ()
    if pos != seg.start {
      targets.push(seg.start)
    } else if seg-idx > 0 {
      // consider previous segment
      targets.push(segments.at(seg-idx - 1).start)
    }
    if pos != seg.end {
      targets.push(seg.end)
    } else if seg-idx + 1 < segments.len() {
      // consider next segment
      targets.push(segments.at(seg-idx + 1).end)
    }

    for target in targets {
      let angle = calc.atan2(target.at(0) - pos.at(0), target.at(1) - pos.at(1))
      if angle <= -22.5deg { angle += 360deg }
      let di = calc.rem(int((angle + 22.5deg) / 45deg), 8)
      let di1 = calc.rem(di + 1, 8) // next
      let di2 = calc.rem(di + 7, 8) // prev
      punishment.at(di) += 16
      if calc.rem(di, 2) == 0 {
        // right, left, up, down
        punishment.at(di1) += 1
        punishment.at(di2) += 1
      } else if di == 1 or di == 5 {
        punishment.at(di1) += 8
        punishment.at(di2) += 4
      } else if di == 3 or di == 7 {
        punishment.at(di1) += 4
        punishment.at(di2) += 8
      }
    }
  }
  // find the direction with minimum punishment
  return _anchors.at(min-index(punishment))
}

#let get-best-anchor(seg) = {
  let angle = seg.angle + 90deg
  if angle <= -22.5deg { angle += 180deg }
  let q = calc.rem(int((angle + 22.5deg) / 45.0deg), 4)
  return _anchors.at(q)
}

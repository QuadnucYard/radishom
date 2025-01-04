#import "../deps.typ": cetz
#import "../dir.typ": dirs
#import "../line.typ": get-segment-of-station, get-station-by-id
#import "../metro.typ": get-line-by-id
#import "../utils.typ": min-index


#let _anchors = (dirs.W, dirs.SW, dirs.S, dirs.NW, dirs.E, dirs.NE, dirs.N, dirs.NW)
#let _anchor-orders = (0, 2, 1, 3)

/// Find a best anchor placement with least punishment.
#let _get-best-anchor-tr(metro, sta-id) = {
  let punishment = (0, 1) * 4 // for 0deg, 45deg, ..., 315deg; prefer ortho
  for line-id in metro.transfers.at(sta-id) {
    let line2 = get-line-by-id(metro, line-id)
    if line2.disabled { continue }
    let sta2 = get-station-by-id(line2, sta-id)
    if sta2.disabled { continue }
    let seg = line2.segments.at(sta2.segment)
    if seg.disabled { continue }
    let pos = sta2.pos

    // collect ray targets
    let targets = ()
    if cetz.vector.dist(pos, seg.start) > 1e-1 {
      targets.push(seg.start)
    } else if sta2.segment > 0 {
      // consider previous segment
      targets.push(line2.segments.at(sta2.segment - 1).start)
    }
    if cetz.vector.dist(pos, seg.end) > 1e-1 {
      targets.push(seg.end)
    } else if sta2.segment + 1 < line2.segments.len() {
      // consider next segment
      targets.push(line2.segments.at(sta2.segment + 1).end)
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

#let get-best-anchor(metro, line, sta) = {
  if sta.transfer == none or sta.id not in metro.transfers {
    let angle = line.segments.at(sta.segment).angle + 90deg
    if angle <= -22.5deg { angle += 180deg }
    let q = calc.rem(int((angle + 22.5deg) / 45.0deg), 4)
    return _anchors.at(q)
  }
  return _get-best-anchor-tr(metro, sta.id)
}

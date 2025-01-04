#import "dir.typ": dirs
#import "utils.typ": lerp


#let pin(
  x: auto,
  y: auto,
  dx: auto,
  dy: auto,
  d: auto,
  pin: none,
  end: false,
  layer: auto,
  cfg: auto,
  cfg-not: auto,
  corner-radius: none,
) = {
  (
    x: x,
    y: y,
    dx: dx,
    dy: dy,
    d: d,
    pin: pin,
    end: end,
    layer: layer,
    cfg: cfg,
    cfg-not: cfg-not,
    corner-radius: corner-radius,
  )
}

#let _resolve-moved(end-pos, last-pos, dir) = {
  if end-pos.x == auto {
    end-pos.x = if dir == dirs.E or dir == dirs.W {
      last-pos.x + end-pos.dx
    } else if dir == dirs.N or dir == dirs.S {
      last-pos.x
    } else if dir == dirs.NE or dir == dirs.SW {
      let dx = if end-pos.dx != auto {
        end-pos.dx
      } else if end-pos.dy != auto {
        end-pos.dy
      } else {
        end-pos.y - last-pos.y
      }
      last-pos.x + dx
    } else if dir == dirs.SE or dir == dirs.NW {
      let dx = if end-pos.dx != auto {
        end-pos.dx
      } else if end-pos.dy != auto {
        -end-pos.dy
      } else {
        -(end-pos.y - last-pos.y)
      }
      last-pos.x + dx
    } else {
      panic()
    }
  }
  if end-pos.y == auto {
    end-pos.y = if dir == dirs.N or dir == dirs.S {
      last-pos.y + end-pos.dy
    } else if dir == dirs.E or dir == dirs.W {
      last-pos.y
    } else if dir == dirs.NE or dir == dirs.SW {
      let dy = if end-pos.dy != auto {
        end-pos.dy
      } else if end-pos.dx != auto {
        end-pos.dx
      } else {
        end-pos.x - last-pos.x
      }
      last-pos.y + dy
    } else if dir == dirs.SE or dir == dirs.NW {
      let dy = if end-pos.dy != auto {
        end-pos.dy
      } else if end-pos.dx != auto {
        -end-pos.dx
      } else {
        -(end-pos.x - last-pos.x)
      }
      last-pos.y + dy
    } else {
      panic([#end-pos #last-pos #dir])
    }
  }
  end-pos
}

#let _extract-stations(points, line-id) = {
  assert(points.len() >= 2, message: "The metro line must have at least two points!")

  let last-pin = points.at(0) // resolved point
  let cur-cfg = if last-pin.cfg == auto { none } else { last-pin.cfg }
  let cur-cfg-not = if last-pin.cfg-not == auto { none } else { last-pin.cfg-not }
  let cur-layer = if last-pin.layer == auto { 0 } else { last-pin.layer }

  let sections = ()
  let section-points = ((last-pin.x, last-pin.y),)
  let segments = ()
  let stations = ()

  let i = 1 // index of control point
  while i < points.len() {
    let j = i
    while "id" in points.at(j) {
      j += 1 // skip stations
    }
    let cur-point = points.at(j) // a pin

    let end-pos = _resolve-moved(cur-point, last-pin, cur-point.d)

    let (sx, sy) = (last-pin.x, last-pin.y)
    let (tx, ty) = (end-pos.x, end-pos.y)
    let angle = calc.atan2(tx - sx, ty - sy)

    let seg = (
      start: (sx, sy),
      end: (tx, ty),
      angle: angle,
      range: (start: stations.len(), end: stations.len() + j - i),
      layer: cur-layer,
      cfg: cur-cfg,
      cfg-not: cur-cfg-not,
    )

    // process stations on this segment
    for sta in points.slice(i, j) {
      sta.segment = segments.len()

      let (x, y, r, dx, dy) = sta.remove("raw-pos")
      if x == auto and dx != auto {
        x = sx + dx
      }
      if y == auto and dy != auto {
        y = sy + dy
      }
      if r != auto {
        x = lerp(sx, tx, r)
        y = lerp(sy, ty, r)
      } else if x == auto and y != auto {
        x = (y - sy) / (ty - sy) * (tx - sx) + sx
      } else if y == auto and x != auto {
        y = (x - sx) / (tx - sx) * (ty - sy) + sy
      }
      sta.line = line-id
      sta.pos = if x == auto or y == auto { auto } else { (x, y) } // mark pos auto, handle it later
      stations.push(sta)
    }
    segments.push(seg)

    // update current pin and cfg
    last-pin = end-pos
    if last-pin.layer != auto {
      cur-cfg-not = last-pin.layer
    }
    if last-pin.cfg != auto {
      cur-cfg = last-pin.cfg
    }
    if last-pin.cfg-not != auto {
      cur-cfg-not = last-pin.cfg-not
    }

    // add section point
    section-points.push(if end-pos.corner-radius == none {
      seg.end
    } else {
      (seg.end, end-pos.corner-radius)
    })
    if seg.cfg != cur-cfg or seg.cfg-not != cur-cfg-not or seg.layer != cur-layer {
      sections.push((points: section-points, layer: seg.layer, cfg: seg.cfg, cfg-not: seg.cfg-not))
      section-points = (seg.end,)
    }

    i = j + 1
  }
  if section-points.len() > 0 {
    sections.push((points: section-points, layer: cur-layer, cfg: cur-cfg, cfg-not: cur-cfg-not))
  }

  // Set positions for terminal stations
  if stations.len() > 0 {
    if stations.first().pos == auto {
      stations.first().pos = segments.first().start
    }
    if stations.last().pos == auto {
      stations.last().pos = segments.last().end
    }
  }

  return (stations: stations, sections: sections, segments: segments)
}

#let line(
  number: "1",
  color: blue,
  index: auto,
  optional: false,
  features: (:),
  default-features: (),
  ..points,
) = {
  let (stations, sections, segments) = _extract-stations(points.pos(), number)
  let station-indexer = stations.enumerate().map(((i, sta)) => (sta.id, i)).to-dict()
  (
    number: number,
    color: color,
    index: index,
    sections: sections,
    segments: segments,
    stations: stations,
    station-indexer: station-indexer,
    optional: optional,
    features: features,
    default-features: default-features,
  )
}

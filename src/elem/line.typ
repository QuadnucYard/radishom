#import "../core/dir.typ": dirs
#import "../core/utils.typ": lerp


#let pin(
  x: auto,
  y: auto,
  dx: auto,
  dy: auto,
  d: auto,
  end: false,
  cfg: auto,
  cfg-not: auto,
  layer: auto,
  stroke: auto,
  corner-radius: none,
  ..metadata,
) = {
  (
    x: x,
    y: y,
    dx: dx,
    dy: dy,
    d: d,
    end: end,
    cfg: cfg,
    cfg-not: cfg-not,
    layer: layer,
    stroke: stroke,
    corner-radius: corner-radius,
    metadata: metadata.named(),
  )
}

#let _resolve-moved(end-pos, last-pos, dir) = {
  if end-pos.x == auto {
    end-pos.x = if dir == auto {
      if end-pos.dx != auto {
        last-pos.x + end-pos.dx
      } else {
        last-pos.x
      }
    } else if dir == dirs.E or dir == dirs.W {
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
      last-pos.x
    }
  }
  if end-pos.y == auto {
    end-pos.y = if dir == auto {
      if end-pos.dy != auto {
        last-pos.y + end-pos.dy
      } else {
        last-pos.y
      }
    } else if dir == dirs.N or dir == dirs.S {
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
      last-pos.y
    }
  }
  end-pos
}

#let _extract-stations(points, line-id) = {
  assert(points.len() >= 2, message: "The metro line must have at least two points!")

  let last-pin = points.at(0) // resolved point
  let cur-attrs = (
    cfg: if last-pin.cfg == auto { none } else { last-pin.cfg },
    cfg-not: if last-pin.cfg-not == auto { none } else { last-pin.cfg-not },
    layer: if last-pin.layer == auto { 0 } else { last-pin.layer },
    stroke: last-pin.stroke,
    metadata: last-pin.metadata,
  )

  let sections = ()
  let section-points = ((last-pin.x, last-pin.y),)
  let segments = ()
  let stations = ()

  let first = 1 // index of control point
  while first < points.len() {
    let last = first
    while "id" in points.at(last) {
      last += 1 // skip stations
    }
    let tar-pos = {
      let cur-point = points.at(last) // a pin
      _resolve-moved(cur-point, last-pin, cur-point.d)
    }

    let (sx, sy) = (last-pin.x, last-pin.y)
    let (tx, ty) = (tar-pos.x, tar-pos.y)
    let angle = calc.atan2(tx - sx, ty - sy)

    let seg = (
      start: (sx, sy),
      end: (tx, ty),
      angle: angle,
      range: (start: stations.len(), end: stations.len() + last - first),
      cfg: cur-attrs.cfg,
      cfg-not: cur-attrs.cfg-not,
    )

    // process stations on this segment
    for sta in points.slice(first, last) {
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
    if tar-pos.end {
      stations.last().trunc = true // mark section truncated here
      if stations.last().pos == auto {
        stations.last().pos = seg.end
      }
    }
    segments.push(seg)

    // update current pin and cfg
    let prev-attrs = cur-attrs
    if tar-pos.cfg != auto { cur-attrs.cfg = tar-pos.cfg }
    if tar-pos.cfg-not != auto { cur-attrs.cfg-not = tar-pos.cfg-not }
    if tar-pos.layer != auto { cur-attrs.cfg-not = tar-pos.layer }
    if tar-pos.stroke != auto { cur-attrs.stroke = tar-pos.stroke }
    cur-attrs.metadata += tar-pos.metadata

    // add section point
    if not last-pin.end {
      section-points.push(if tar-pos.corner-radius == none {
        seg.end
      } else {
        (seg.end, tar-pos.corner-radius)
      })
    }

    if last-pin.end or cur-attrs != prev-attrs {
      sections.push((points: section-points, ..prev-attrs))
      section-points = (seg.end,)
    }

    last-pin = tar-pos
    first = last + 1
  }
  if section-points.len() > 0 {
    sections.push((points: section-points, ..cur-attrs))
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
  id: "1",
  color: gray,
  index: auto,
  optional: false,
  features: (:),
  default-features: (),
  stroke: auto,
  ..points,
) = {
  let (stations, sections, segments) = _extract-stations(points.pos(), id)
  let station-indexer = stations.enumerate().map(((i, sta)) => (sta.id, i)).to-dict()
  let data = (
    id: id,
    color: color,
    index: index,
    sections: sections,
    segments: segments,
    stations: stations,
    station-indexer: station-indexer,
    optional: optional,
    features: features,
    default-features: default-features,
    metadata: points.named(),
  )
  if stroke != auto { data.stroke = stroke }
  data
}

#import "utils.typ": lerp


#let dirs = (
  north: "N",
  south: "S",
  west: "W",
  east: "E",
  north-east: "NE",
  north-west: "NW",
  south-east: "SE",
  south-west: "SW",
)

#let anchors = ("south", "north-west", "west", "south-west")


#let pin(x: auto, y: auto, dx: auto, dy: auto, d: auto, pin: none, cfg: auto, cfg-not: auto) = {
  (x: x, y: y, dx: dx, dy: dy, d: d, pin: pin, end: end, cfg: cfg, cfg-not: cfg-not)
}

#let resolve-moved(end-pos, last-pos, dir) = {
  if end-pos.x == auto {
    end-pos.x = if dir == dirs.east or dir == dirs.west {
      last-pos.x + end-pos.dx
    } else if dir == dirs.north or dir == dirs.south {
      last-pos.x
    } else if dir == dirs.north-east or dir == dirs.south-west {
      let dx = if end-pos.dx != auto {
        end-pos.dx
      } else if end-pos.dy != auto {
        end-pos.dy
      } else {
        end-pos.y - last-pos.y
      }
      last-pos.x + dx
    } else if dir == dirs.south-east or dir == dirs.north-west {
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
    end-pos.y = if dir == dirs.north or dir == dirs.south {
      last-pos.y + end-pos.dy
    } else if dir == dirs.east or dir == dirs.west {
      last-pos.y
    } else if dir == dirs.north-east or dir == dirs.south-west {
      let dy = if end-pos.dy != auto {
        end-pos.dy
      } else if end-pos.dx != auto {
        end-pos.dx
      } else {
        end-pos.x - last-pos.x
      }
      last-pos.y + dy
    } else if dir == dirs.south-east or dir == dirs.north-west {
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

#let extract-stations(points, line-num) = {
  assert(points.len() >= 2, message: "The metro line must have at least two points!")
  // assert(type(points.at(0)) == array, message: "The first point must be position!")
  // assert(type(points.at(-1)) == array, message: "The last point must be position!")

  let last-pin = points.at(0) // resolved point
  let cur-cfg = last-pin.cfg
  let cur-cfg-not = last-pin.cfg-not
  let segments = ()
  let stations = ()
  let i = 1 // index of control point
  while i < points.len() {
    let j = i
    while "id" in points.at(j) {
      j += 1 // skip stations
    }
    let cur-point = points.at(j)

    let end-pos = resolve-moved(cur-point, last-pin, cur-point.d)

    let seg = (
      start: (last-pin.x, last-pin.y),
      end: (end-pos.x, end-pos.y),
      range: (start: stations.len(), end: stations.len() + j - i),
      cfg: if cur-cfg == auto { none } else { cur-cfg },
      cfg-not: if cur-cfg-not == auto { none } else { cur-cfg-not },
    )

    let (sx, sy) = seg.start
    let (tx, ty) = seg.end
    let angle = calc.atan2(tx - sx, ty - sy)
    let q = calc.rem(int((angle + 22.5deg + 180deg) / 45.0deg), 4)

    // process stations on this segment
    for sta in points.slice(i, j) {
      sta.segment = segments.len()
      if sta.anchor == auto {
        sta.anchor = anchors.at(q)
      }

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
      } else if x == auto or y == auto {
        // handle it later
        sta.line = line-num
        sta.pos = auto
        stations.push(sta)
        continue
      }
      assert(x != auto and y != auto)
      sta.line = line-num
      sta.pos = (x, y)
      stations.push(sta)
    }

    segments.push(seg)
    last-pin = end-pos
    if last-pin.cfg != auto {
      cur-cfg = last-pin.cfg
    }
    if last-pin.cfg-not != auto {
      cur-cfg-not = last-pin.cfg-not
    }
    i = j + 1
  }

  // collect sections, split by features
  let sections = ()
  i = 0
  while i < segments.len() {
    let cfg = segments.at(i).cfg
    let cp = (segments.at(i).start, segments.at(i).end)
    let j = i
    while j < segments.len() and segments.at(j).cfg == cfg {
      cp.push(segments.at(j).end)
      j += 1
    }
    sections.push((points: cp, cfg: cfg))
    i = j
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
  let (stations, sections, segments) = extract-stations(points.pos(), number)
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

#let get-station-by-id(line, sta-id) = {
  let index = line.station-indexer.at(sta-id, default: none)
  if index != none {
    line.stations.at(index)
  } else {
    none
  }
}

#let get-segment-of-station(line, sta) = {
  line.segments.at(sta.segment)
}

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


#let pin(x: auto, y: auto, dx: auto, dy: auto, d: auto, pin: none) = {
  (x: x, y: y, dx: dx, dy: dy, d: d, pin: pin)
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

#let line(number: "1", color: blue, index: auto, ..points) = {
  let points = points.pos()
  assert(points.len() >= 2, message: "The metro line must have at least two points!")
  // assert(type(points.at(0)) == array, message: "The first point must be position!")
  // assert(type(points.at(-1)) == array, message: "The last point must be position!")

  let last-pos = points.at(0) // resolved point
  let control-points = ((last-pos.x, last-pos.y),)
  let segments = ()
  let stations = ()
  let i = 1 // index of control point
  while i < points.len() {
    let j = i
    while "id" in points.at(j) {
      j += 1
    }
    let cur-point = points.at(j)

    let end-pos = resolve-moved(cur-point, last-pos, cur-point.d)

    let seg = (
      start: (last-pos.x, last-pos.y),
      end: (end-pos.x, end-pos.y),
      range: (start: stations.len(), end: stations.len() + j - i),
    )

    let (sx, sy) = seg.start
    let (tx, ty) = seg.end
    let angle = calc.atan2(tx - sx, ty - sy)
    let q = calc.rem(int((angle + 22.5deg + 180deg) / 45.0deg), 4)

    // process stations on this segment
    for sta in points.slice(i, j) {
      sta.segment = seg
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
        sta.pos = auto
        stations.push(sta)
        continue
      }
      assert(x != auto and y != auto)
      sta.pos = (x, y)
      stations.push(sta)
    }

    segments.push(seg)
    last-pos = end-pos
    control-points.push(seg.end)
    i = j + 1
  }

  // Set positions for terminal stations
  if stations.len() > 0 {
    if stations.first().pos == auto {
      stations.first().pos = stations.first().segment.start
    }
    if stations.last().pos == auto {
      stations.last().pos = stations.last().segment.end
    }
  }
  let station-indexer = stations.enumerate().map(((i, sta)) => (sta.id, i)).to-dict()
  (
    number: number,
    color: color,
    index: index,
    control-points: control-points,
    segments: segments,
    stations: stations,
    station-indexer: station-indexer,
  )
}

#let get-station-by-id(line, sta-id) = {
  if sta-id in line.station-indexer {
    return line.stations.at(line.station-indexer.at(sta-id))
  }
}

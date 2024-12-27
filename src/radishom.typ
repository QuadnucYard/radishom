#import "deps.typ": cetz
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

#let ensure-transfer(transfer) = {
  if transfer == auto {
    auto
  } else if transfer == none {
    ()
  } else if type(transfer) == str {
    (transfer,)
  } else {
    transfer
  }
}

#let station(
  name,
  subname,
  id: auto,
  x: auto,
  y: auto,
  dx: auto,
  dy: auto,
  r: auto,
  offset: (0, 0),
  anchor: auto,
  hidden: false,
  transfer: auto,
  pin: none,
) = {
  if id == auto {
    id = if type(name) == str { name } else { name.text }
  }
  (
    id: id,
    name: name,
    subname: subname,
    raw-pos: (x: x, y: y, dx: dx, dy: dy, r: r),
    offset: offset,
    anchor: anchor,
    hidden: hidden,
    transfer: ensure-transfer(transfer),
    pin: pin,
  )
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
  (number: number, color: color, index: index, control-points: control-points, segments: segments, stations: stations)
}

#let find-intersection(lines, line, sta) = {
  if sta.transfer.len() == 0 {
    return none
  }
  // find stations of the same id
  for line2 in lines {
    if line2.number not in sta.transfer { continue }
    for sta2 in line2.stations {
      if sta2.id != sta.id { continue }
      let intersection = cetz.intersection.line-line(
        sta.segment.start,
        sta.segment.end,
        sta2.segment.start,
        sta2.segment.end,
      )
      if intersection != none {
        return intersection.slice(0, 2)
      }
    }
  }
  return none
}

#let get-transfers(self, station-id, lines) = {
  let transfer = ()
  for line2 in lines {
    if line2.number == self.number { continue }
    for sta2 in line2.stations {
      if sta2.id == station-id {
        transfer.push(line2.number)
      }
    }
  }
  return transfer
}

#let resolve-stations(lines) = {
  (lines.enumerate()).map(((i, line)) => {
    // set line index
    if line.index == auto {
      line.index = i
    }
    for (k, sta) in line.stations.enumerate() {
      // resolve station transfer
      if sta.transfer == auto {
        sta.transfer = get-transfers(line, sta.id, lines)
        line.stations.at(k).transfer = sta.transfer
      }
      // resolve station positions by intersection
      if sta.pos == auto {
        // find transfer station with the same name on another line
        let intersection = find-intersection(lines, line, sta)
        if intersection != none {
          sta.pos = intersection
          line.stations.at(k).pos = sta.pos
        }
      }
    }

    // resolve pending positions by interpolation
    for seg in line.segments {
      let start-idx = seg.range.start
      let end-idx = seg.range.end

      let last-known-index = -1
      let last-known = seg.start

      for (k, sta) in line.stations.slice(start-idx, end-idx).enumerate() {
        if sta.pos != auto {
          last-known-index = k
          last-known = sta.pos
          continue
        }
        // find next known
        let next-known = seg.end
        let next-known-index = end-idx - start-idx
        for kk in range(k + 1, end-idx - start-idx) {
          let kkk = start-idx + kk
          if line.stations.at(kkk).pos != auto {
            next-known = line.stations.at(kkk).pos
            next-known-index = kk
            break
          }
        }
        let pos = cetz.vector.lerp(
          last-known,
          next-known,
          (k - last-known-index) / (next-known-index - last-known-index),
        )
        line.stations.at(start-idx + k).pos = pos
      }
    }

    return line
  })
}

#let metro(..lines) = {
  (lines: resolve-stations(lines.pos()))
}

#let diagram(metro, canvas-length: 1cm, grid: auto, line-width: 6pt, corner-radius: 8pt) = {
  let lines = metro.lines
  cetz.canvas(
    length: canvas-length,
    {
      import cetz: draw

      let min-x = 0
      let min-y = 0
      let max-x = 0
      let max-y = 0

      for line in lines {
        draw.line(
          ..line.control-points,
          stroke: stroke(paint: line.color, thickness: line-width, cap: "round", join: "round"),
        )
        // my-line(line.control-points, stroke: stroke(paint: line.color, thickness: line-width))
        //
        // draw stations
        for (j, sta) in line.stations.enumerate() {
          //check marker
          let hidden = (
            sta.hidden
              or sta.transfer.any(tr => lines.any(line2 => (
                line2.number == tr and line2.index < line.index and line2.stations.any(sta2 => sta2.id == sta.id)
              )))
          )

          let pos = sta.pos
          min-x = calc.min(min-x, pos.at(0))
          min-y = calc.min(min-y, pos.at(1))
          max-x = calc.max(max-x, pos.at(0))
          max-y = calc.max(max-y, pos.at(1))

          if not hidden {
            let marker = if sta.transfer.len() > 0 {
              draw.circle(pos, fill: white, stroke: black + 1pt, radius: 6pt)
            } else if j == 0 or j == line.stations.len() - 1 {
              draw.circle(pos, fill: white, stroke: line.color + 1.0pt, radius: 4pt)
            } else {
              draw.circle(pos, fill: white, stroke: none, radius: 2.0pt)
            }
            draw.on-layer(1, marker)
          }

          let label = [
            #show: block.with(inset: 0.6em)
            #set par(spacing: 0.2em)
            #set align(if "west" in sta.anchor {
              left
            } else if "east" in sta.anchor {
              right
            } else {
              center
            })

            #sta.name

            #text(0.45em, sta.subname)
            // #text(0.7em)[#sta.pos]
          ]
          if hidden {
            label = hide(label)
          }
          assert(pos != auto and pos.at(0) != auto, message: repr(sta))

          draw.on-layer(2, draw.content(pos, label, anchor: sta.anchor))
        }
      }

      if grid == auto {
        grid = ((calc.floor(min-x - 0.5), calc.floor(min-y - 0.5)), (calc.ceil(max-x + 0.5), calc.ceil(max-y + 0.5)))
      }
      if grid != none {
        draw.on-layer(-100, draw.grid(..grid, stroke: gray.transparentize(50%)))
      }
    },
  )
}

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

#let pin(x: auto, y: auto, dx: auto, dy: auto, d: auto, pin: none) = {
  (x: x, y: y, dx: dx, dy: dy, d: d, pin: pin)
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
  transfer: none,
  pin: none,
) = {
  if id == auto {
    id = if type(name) == str {
      name
    } else {
      name.text
    }
  }
  (
    id: id,
    name: name,
    subname: subname,
    x: x,
    y: y,
    dx: dx,
    dy: dy,
    r: r,
    offset: offset,
    anchor: anchor,
    hidden: hidden,
    transfer: transfer,
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

#let ensure-transfer(transfer) = {
  if transfer == none {
    ()
  } else if type(transfer) == str {
    (transfer,)
  } else {
    transfer
  }
}

#let line(number: "1", color: blue, index: auto, ..points) = {
  let points = points.pos()
  assert(points.len() >= 2, message: "The metro line must have at least two points!")
  // assert(type(points.at(0)) == array, message: "The first point must be position!")
  // assert(type(points.at(-1)) == array, message: "The last point must be position!")

  let last-point = points.at(0) // unresolved point
  let last-pos = last-point // resolved point
  let control-points = ((last-pos.x, last-pos.y),)
  let segments = ()
  let i = 0 // index of control point
  while i + 1 < points.len() {
    let j = i + 1
    while "id" in points.at(j) {
      j += 1
    }
    let cur-point = points.at(j)

    let end-pos = resolve-moved(cur-point, last-pos, cur-point.d)

    let seg-start = (last-pos.x, last-pos.y)
    let seg-end = (end-pos.x, end-pos.y)
    segments.push((
      start: seg-start,
      end: seg-end,
      stations: points
        .slice(i + 1, j)
        .map(t => (
          t + (segment: (start: seg-start, end: seg-end), transfer: ensure-transfer(t.transfer))
        )),
    ))
    last-pos = end-pos
    control-points.push(seg-end)
    i = j
  }

  // 自动给终点站设置位置
  if segments.first().stations.len() > 0 {
    segments.first().stations.first().x = segments.first().start.at(0)
    segments.first().stations.first().y = segments.first().start.at(1)
  }
  if segments.last().stations.len() > 0 {
    segments.last().stations.last().x = segments.last().end.at(0)
    segments.last().stations.last().y = segments.last().end.at(1)
  }

  (number: number, color: color, index: index, control-points: control-points, segments: segments)
}

#let find-intersection(lines, line, sta) = {
  if sta.transfer.len() == 0 {
    return none
  }
  for line2 in lines {
    for seg2 in line2.segments {
      for sta2 in seg2.stations {
        if sta2.id == sta.id and line.number in sta2.transfer {
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
    }
  }
  return none
}

#let resolve-stations(lines) = {
  let anchors = ("south", "north-west", "west", "south-west")
  for (i, line) in lines.enumerate() {
    let stations = ()
    for (j, seg) in line.segments.enumerate() {
      let (sx, sy) = seg.start
      let (tx, ty) = seg.end
      let angle = calc.atan2(tx - sx, ty - sy)
      let q = calc.rem(int((angle + 22.5deg + 180deg) / 45.0deg), 4)

      let seg-stations = ()
      for (k, sta) in seg.stations.enumerate() {
        if sta.anchor == auto {
          sta.anchor = anchors.at(q)
        }

        let x = sta.remove("x")
        let y = sta.remove("y")
        let r = sta.remove("r")
        let dx = sta.remove("dx")
        let dy = sta.remove("dy")
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
          // find transfer station with the same name on another line
          let intersection = find-intersection(lines, line, sta)
          if intersection != none {
            (x, y) = intersection
          } else {
            sta.pos = none
            seg-stations.push(sta)
            continue
          }
        }
        sta.pos = (x, y)
        seg-stations.push(sta)

        // handle pin
        // if type(sta.pin) == str {
        //   state("metro-pin-" + sta.pin).update((x: x, y: y))
        // }
      }

      // resolve pending positions
      let last-known-index = -1
      let last-known = (sx, sy)
      for (k, sta) in seg-stations.enumerate() {
        if sta.pos == none {
          assert(not (j == 0 and k == 0), message: repr(sta))
          // find next known
          let next-known = (tx, ty)
          let next-known-index = seg-stations.len()
          for kk in range(k + 1, seg-stations.len()) {
            if seg-stations.at(kk).pos != none {
              next-known = seg-stations.at(kk).pos
              next-known-index = kk
              break
            }
          }
          sta.pos = cetz.vector.lerp(
            last-known,
            next-known,
            (k - last-known-index) / (next-known-index - last-known-index),
          )
        } else {
          last-known-index = k
          last-known = sta.pos
        }
        seg-stations.at(k) = sta
      }

      stations += seg-stations
    }
    // lines.at(i).remove("segments")
    if line.index == auto {
      lines.at(i).index = i
    }
    lines.at(i).stations = stations
  }
  return lines
}

#let diagram(canvas-length: 1cm, grid: none, line-width: 6pt, corner-radius: 8pt, ..lines) = {
  let lines = resolve-stations(lines.pos())
  cetz.canvas(
    length: canvas-length,
    {
      import cetz: draw

      if grid != none {
        draw.on-layer(-100, draw.grid(..grid, stroke: gray.transparentize(50%)))
      }

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
          if pos.at(0) == auto {
            panic(sta)
          }

          draw.on-layer(2, draw.content(pos, label, anchor: sta.anchor))
        }
      }
    },
  )
}

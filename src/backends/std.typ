#import "../deps.typ": cetz
#import "../dir.typ": dirs


#let _get-anchor-align(anchor) = {
  let h-align = if "west" in anchor { left } else if "east" in anchor { right } else { center }
  let v-align = if "north" in anchor { top } else if "south" in anchor { bottom } else { horizon }
  h-align + v-align
}

#let _anchored(body, anchor) = context {
  let (width, height) = measure(body)
  let dx = if "west" in anchor { 0pt } else if "east" in anchor { -width } else { -width / 2 }
  let dy = if "north" in anchor { 0pt } else if "south" in anchor { -height } else { -height / 2 }
  move(body, dx: dx, dy: dy)
}

#let _get-canvas(coords, u) = {
  let ((x1, y1), (x2, y2)) = coords
  body => {
    block(
      move(body, dx: -x1 * u, dy: y2 * u),
      width: (x2 - x1) * u,
      height: (y2 - y1) * u,
    )
  }
}

/// Get the position on the canvas.
#let _cpos(pos, u) = {
  (pos.at(0) * u, -pos.at(1) * u)
}

/// Place an element on the canvas with given position.
#let _draw(element, pos, u) = {
  let (x, y) = _cpos(pos, u)
  place(element, dx: x, dy: y)
}

#let _draw-grid(grid, u) = {
  let ((x1, y1), (x2, y2)) = grid.coords
  let pat = pattern(size: (u, u))[
    #rect(width: u, height: u, stroke: grid.stroke)
  ]
  _draw(rect(fill: pat, width: 100%, height: 100%), (x1, y2), u)
}

#let _make-curved(points, u) = {
  let extract(pt) = {
    if type(pt.at(0)) == array { pt.at(0) } else { pt }
  }

  for (i, pt) in points.enumerate() {
    if type(pt.at(0)) == array {
      let (pt, radius) = pt
      let p1 = extract(points.at(i - 1))
      let p2 = extract(points.at(i + 1))
      let d1 = cetz.vector.dist(p1, pt)
      let d2 = cetz.vector.dist(p2, pt)
      let radius = calc.min(radius, d1 / 2, d2 / 2) // clamp radius
      let p1x = cetz.vector.lerp(pt, p1, radius / d1) // arc point 1
      let p2x = cetz.vector.lerp(pt, p2, radius / d2) // arc point 2
      let p1m = cetz.vector.lerp(pt, p1x, 0.5)
      let p2m = cetz.vector.lerp(pt, p2x, 0.5)
      (
        (_cpos(p1x, u), (0pt, 0pt), _cpos(cetz.vector.sub(p1m, p1x), u)),
        (_cpos(p2x, u), _cpos(cetz.vector.sub(p2m, p2x), u), (0pt, 0pt)),
      )
    } else {
      (_cpos(pt, u),)
    }
  }
}

#let default-marker-renderer(line, station, has-transfer: false) = {
  if has-transfer {
    circle(fill: white, stroke: black + 1pt, radius: 6pt)
  } else if "terminal" in station {
    circle(fill: white, stroke: line.color + 1.0pt, radius: 4pt)
  } else {
    circle(fill: white, stroke: none, radius: 2.0pt)
  }
}

#let render(task, unit-length) = {
  show: _get-canvas(task.grid.coords, unit-length)

  if task.grid != none {
    _draw-grid(task.grid, unit-length)
  }

  for line in task.lines {
    let points = _make-curved(line.points, unit-length)
    place(path(..points, stroke: line.stroke))
  }

  for marker in task.markers {
    _draw(block(width: 0pt, height: 0pt, align(center + horizon, marker.body)), marker.pos, unit-length)
  }

  for label in task.labels {
    let content = _anchored(label.body, label.anchor)
    if label.hidden {
      content = hide(content)
    }
    _draw(content, label.pos, unit-length)
  }
}

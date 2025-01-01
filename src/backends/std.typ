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
#let _canvas-pos(pos, u) = {
  (pos.at(0) * u, -pos.at(1) * u)
}

/// Place an element on the canvas with given position.
#let _draw(element, pos, u) = {
  let (x, y) = _canvas-pos(pos, u)
  place(element, dx: x, dy: y)
}

#let _draw-grid(grid, u) = {
  let ((x1, y1), (x2, y2)) = grid.coords
  let pat = pattern(size: (u, u))[
    #rect(width: u, height: u, stroke: grid.stroke)
  ]
  _draw(rect(fill: pat, width: 100%, height: 100%), (x1, y2), u)
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
    show: place
    path(
      ..line.points.map(pt => _canvas-pos(pt, unit-length)),
      stroke: line.stroke,
    )
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

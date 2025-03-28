#import "../core/dir.typ": dirs


#let _zero-pos = (0, 0)

#let _get-anchor-align(anchor) = {
  let h-align = if "west" in anchor { left } else if "east" in anchor { right } else { center }
  let v-align = if "north" in anchor { top } else if "south" in anchor { bottom } else { horizon }
  h-align + v-align
}

#let _anchored(body, anchor) = {
  place(_get-anchor-align(anchor), body)
}

#let _get-canvas(coords, u, fill: white) = {
  let ((x1, y1), (x2, y2)) = coords
  body => block(
    move(body, dx: -x1 * u, dy: y2 * u),
    width: (x2 - x1) * u,
    height: (y2 - y1) * u,
    fill: fill,
  )
}

/// Get the position on the canvas.
#let _cpos(pos, u) = {
  (pos.at(0) * u, -pos.at(1) * u)
}

/// Place an element on the canvas with given position.
#let _draw(element, pos, u) = {
  let (x, y) = pos
  place(element, dx: x * u, dy: y * -u)
}

#let _draw-grid(grid, u) = {
  let ((x1, y1), (x2, y2)) = grid.coords
  let pat = tiling(size: (u, u))[
    #rect(width: u, height: u, stroke: grid.stroke)
  ]
  _draw(rect(fill: pat, width: 100%, height: 100%), (x1, y2), u)

  for x in range(calc.ceil(x1 / 5) * 5, calc.floor(x2 / 5) * 5 + 1, step: 5) {
    place(line(start: (x * u, -y1 * u), end: (x * u, -y2 * u), stroke: grid.heavy-stroke))
  }
  for y in range(calc.ceil(y1 / 5) * 5, calc.floor(y2 / 5) * 5 + 1, step: 5) {
    place(line(start: (x1 * u, -y * u), end: (x2 * u, -y * u), stroke: grid.heavy-stroke))
  }
}

/* Calculates a rounded corner between two line segments.
 *
 * Parameters:
 * - pt: (float, float) The corner point where the two lines meet
 * - p1: (float, float) The endpoint of the first line segment
 * - p2: (float, float) The endpoint of the second line segment
 * - radius: float The desired radius of the rounded corner
 * - u: float Scale factor for the output coordinates
 *
 * Returns:
 * A tuple containing two curve segments that form the rounded corner:
 * - A line segment from the first arc point
 * - A cubic Bézier curve connecting the two arc points
 *
 * The function clamps the radius to prevent it from exceeding half the length
 * of either line segment. It generates a smooth transition between the lines
 * using a combination of a straight line and a cubic Bézier curve.
 * The resulting coordinates are scaled by factor u, with y-coordinates inverted.
 */
#let _round-corner(pt, p1, p2, radius, u) = {
  // here we avoid func-call to improve performance
  let (x0, y0) = pt
  let (x1, y1) = p1
  let (x2, y2) = p2
  let d1 = calc.sqrt((x1 - x0) * (x1 - x0) + (y1 - y0) * (y1 - y0))
  let d2 = calc.sqrt((x2 - x0) * (x2 - x0) + (y2 - y0) * (y2 - y0))
  let radius = calc.min(radius, d1 / 2, d2 / 2) // clamp radius
  let arc-x1 = x0 + (x1 - x0) * radius / d1 // arc point 1
  let arc-y1 = y0 + (y1 - y0) * radius / d1
  let arc-x2 = x0 + (x2 - x0) * radius / d2 // arc point 2
  let arc-y2 = y0 + (y2 - y0) * radius / d2
  let ct-x1 = (x0 + arc-x1) * 0.5
  let ct-y1 = (y0 + arc-y1) * 0.5
  let ct-x2 = (x0 + arc-x2) * 0.5
  let ct-y2 = (y0 + arc-y2) * 0.5
  (
    curve.line((arc-x1 * u, arc-y1 * -u)),
    curve.cubic((ct-x1 * u, ct-y1 * -u), (ct-x2 * u, ct-y2 * -u), (arc-x2 * u, arc-y2 * -u)),
  )
}

/// Creates a sequence of curve points from given points with optional corner rounding
///
/// Parameters:
/// - points: Array of points where each point can be either:
///   - A simple coordinate pair (x, y)
///   - An array containing a coordinate pair and a radius for rounded corners
/// - u: Scaling factor for coordinates
///
/// Returns:
/// Array of curve commands (move and line operations) with coordinates scaled by u
/// and y-coordinates inverted. If a point includes a radius, it generates rounded
/// corners using _round-corner function.
///
/// Example:
/// ```typst
/// let points = ((0,0), ((1,1), 0.5), (2,0))
/// _make-curve(points, 10)
/// ```
#let _make-curve(points, u) = {
  let extract(pt) = {
    if type(pt.at(0)) == array { pt.at(0) } else { pt }
  }

  let curve-points = for (i, pt) in points.enumerate() {
    if type(pt.at(0)) == array {
      let (pt, radius) = pt
      let p1 = extract(points.at(i - 1))
      let p2 = extract(points.at(i + 1))
      _round-corner(pt, p1, p2, radius, u)
    } else {
      let (x, y) = pt
      if i == 0 {
        (curve.move((x * u, y * -u)),)
      } else {
        (curve.line((x * u, y * -u)),)
      }
    }
  }
  curve-points
}

#let _draw-polygon(p, u) = {
  let radius = p.at("corner-radius", default: 0)

  let vertices = p.vertices
  let points = if radius <= 0 {
    // Simple polygon case
    vertices.map(pt => _cpos(pt, u))
  } else {
    // Rounded corner case
    let (x0, y0) = vertices.at(0)
    vertices.push(vertices.at(0))
    vertices.push(vertices.at(1))
    (
      curve.move((x0 * u, y0 * -u)),
      ..for (p1, pt, p2) in vertices.windows(3) {
        _round-corner(pt, p1, p2, radius, u)
      },
    )
  }
  let shape = curve(..points, fill: p.fill, stroke: p.stroke)
  place(shape)
}

/* Renders a visual task with various graphical elements.

This function takes a task object and a unit length, then renders all components
of the task including backgrounds, grids, lines, markers, labels and foreground elements.

Parameters:
- task: A task object containing:
  - grid: Grid configuration with coordinates
  - background-color: Color for the canvas background
  - background: Array of background elements (polygons with optional labels)
  - show-grid: Boolean controlling grid visibility
  - lines: Array of line objects with points and stroke styles, sorted by layer
  - markers: Array of marker objects with body content and position
  - labels: Array of label objects with body, position and visibility settings
  - foreground: Array of foreground elements with body and position
- unit-length: The base unit length for scaling coordinates

The render order is:
1. Canvas with background color
2. Background elements
3. Grid (if enabled)
4. Lines (sorted by layer)
5. Markers
6. Labels
7. Foreground elements

Each element is placed according to its specified position scaled by the unit-length.
*/
#let render(task, unit-length) = {
  show: _get-canvas(task.grid.coords, unit-length, fill: task.background-color)

  for bg in task.background {
    if bg.kind == "polygon" {
      _draw-polygon(bg, unit-length)
    }
    if bg.label != none and bg.label-pos != none {
      _draw(bg.label, bg.label-pos, unit-length)
    }
  }

  if task.show-grid {
    _draw-grid(task.grid, unit-length)
  }

  for line in task.lines.sorted(key: l => l.layer) {
    let curve-points = _make-curve(line.points, unit-length)
    if type(line.stroke) == array {
      for line-stroke in line.stroke {
        place(curve(..curve-points, stroke: line-stroke))
      }
    } else {
      place(curve(..curve-points, stroke: line.stroke))
    }
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

  for fg in task.foreground {
    let body = if "anchor" in fg {
      _anchored(fg.body, fg.anchor)
    } else {
      fg.body
    }
    _draw(body, fg.pos, unit-length)
  }
}

#import "../deps.typ": cetz


#let default-marker-renderer(line, station, has-transfer: false) = {
  if has-transfer {
    cetz.draw.circle((), fill: white, stroke: black + 1pt, radius: 6pt)
  } else if "terminal" in station {
    cetz.draw.circle((), fill: white, stroke: line.color + 1.0pt, radius: 4pt)
  } else {
    cetz.draw.circle((), fill: white, stroke: none, radius: 2.0pt)
  }
}

#let render(task, unit-length) = {
  import cetz.draw
  cetz.canvas(
    length: unit-length,
    {
      if task.grid != none {
        draw.on-layer(-100, draw.grid(..task.grid.coords, stroke: task.grid.stroke))
      }

      for line in task.lines {
        draw.line(..line.points, stroke: line.stroke)
      }

      for marker in task.markers {
        draw.move-to(marker.pos)
        draw.on-layer(10, marker.body)
      }

      for label in task.labels {
        let content = draw.content(label.pos, label.body, anchor: label.anchor)
        if label.hidden {
          content = draw.hide(content)
        }
        draw.on-layer(20, content)
      }
    },
  )
}

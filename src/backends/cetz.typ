#import "../deps.typ": cetz


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

#import "deps.typ": cetz
#import "line.typ": get-station-by-id
#import "metro.typ": get-transfer-marker-pos


#let radishom(metro, canvas-length: 1cm, grid: auto, line-width: 6pt, corner-radius: 8pt) = {
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
                line2.number == tr and line2.index < line.index and get-station-by-id(line2, sta.id) != none
              )))
          )

          let pos = sta.pos
          min-x = calc.min(min-x, pos.at(0))
          min-y = calc.min(min-y, pos.at(1))
          max-x = calc.max(max-x, pos.at(0))
          max-y = calc.max(max-y, pos.at(1))

          if not hidden {
            let marker = if sta.transfer.len() > 0 {
              let marker-pos = get-transfer-marker-pos(sta.id, lines)
              draw.circle(marker-pos, fill: white, stroke: black + 1pt, radius: 6pt)
            } else if j == 0 or j == line.stations.len() - 1 {
              draw.circle(pos, fill: white, stroke: line.color + 1.0pt, radius: 4pt)
            } else {
              draw.circle(pos, fill: white, stroke: none, radius: 2.0pt)
            }
            draw.on-layer(1, marker)
          }

          let label = [
            #show: block.with(inset: (x: 0.6em, y: 0.4em))
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

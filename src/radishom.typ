#import "deps.typ": cetz
#import "line.typ": get-station-by-id
#import "metro.typ": get-line-by-id, get-transfer-marker-pos


#let default-line-stroke(line, thickness: 6pt) = stroke(
  paint: line.color,
  thickness: thickness,
  cap: "round",
  join: "round",
)

#let default-label-renderer(station) = {
  show: block.with(inset: (x: 0.6em, y: 0.4em))
  set par(spacing: 0.2em)
  set smartquote(enabled: false)
  set align(if "west" in station.anchor { left } else if "east" in station.anchor { right } else { center })

  [
    #station.name

    #text(0.5em, station.subname)
  ]
}

#let radishom(
  metro,
  backend: "cetz",
  unit-length: 1cm,
  grid: auto,
  line-width: 6pt,
  corner-radius: 8pt,
  line-stroker: auto,
  marker-renderer: auto,
  label-renderer: auto,
) = {
  let (backend, canvas, draw) = if backend == "cetz" {
    import "backends/cetz.typ" as cetz-be
    (cetz-be, cetz.canvas, cetz.draw)
  }
  if line-stroker == auto { line-stroker = default-line-stroke }
  if marker-renderer == auto { marker-renderer = backend.default-marker-renderer }
  if label-renderer == auto { label-renderer = default-label-renderer }

  canvas(
    length: unit-length,
    {
      let min-x = 0
      let min-y = 0
      let max-x = 0
      let max-y = 0

      for line in metro.lines {
        if line.disabled {
          continue
        }
        for cp in line.sections {
          if not cp.disabled {
            draw.line(..cp.points, stroke: line-stroker(line))
          }
        }

        // draw stations
        for (j, sta) in line.stations.enumerate() {
          if sta.disabled {
            continue
          }

          let has-transfer = sta.id in metro.enabled-transfers
          let is-not-first-transfer = has-transfer and line.number != metro.enabled-transfers.at(sta.id).at(0)

          //check marker
          let hidden = sta.hidden or is-not-first-transfer

          let pos = sta.pos
          assert(pos != auto and pos.at(0) != auto, message: repr(sta))
          min-x = calc.min(min-x, pos.at(0))
          min-y = calc.min(min-y, pos.at(1))
          max-x = calc.max(max-x, pos.at(0))
          max-y = calc.max(max-y, pos.at(1))

          if not hidden {
            let marker-pos = if has-transfer {
              get-transfer-marker-pos(metro, sta.id)
            } else {
              pos
            }
            let marker = marker-renderer(line, sta, pos: marker-pos, has-transfer: has-transfer)
            draw.on-layer(1, marker)
          }

          let label = label-renderer(sta)
          if hidden {
            label = hide(label)
          }

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

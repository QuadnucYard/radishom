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
  line-stroker: auto,
  marker-renderer: auto,
  label-renderer: auto,
) = {
  let backend = if backend == "cetz" {
    import "backends/cetz.typ" as cetz-be
    cetz-be
  } else if backend == "std" {
    import "backends/std.typ" as std-be
    std-be
  } else {
    panic("unknown backend: " + backend)
  }
  if line-stroker == auto { line-stroker = default-line-stroke }
  if marker-renderer == auto { marker-renderer = backend.default-marker-renderer }
  if label-renderer == auto { label-renderer = default-label-renderer }

  // render task
  let task = (lines: (), markers: (), labels: ())

  let (min-x, min-y, max-x, max-y) = (0, 0, 0, 0)

  for line in metro.lines {
    if line.disabled {
      continue
    }

    let line-stroke = line-stroker(line)
    for sec in line.sections {
      if not sec.disabled {
        task.lines.push((points: sec.points, stroke: line-stroke))
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
        let marker = marker-renderer(line, sta, has-transfer: has-transfer)
        task.markers.push((pos: marker-pos, body: marker))
      }

      let label = label-renderer(sta)
      task.labels.push((pos: pos, body: label, anchor: sta.anchor, hidden: hidden))
    }
  }

  task.show-grid = grid != none
  if grid == auto or grid == none {
    grid = ((calc.floor(min-x - 0.5), calc.floor(min-y - 0.5)), (calc.ceil(max-x + 0.5), calc.ceil(max-y + 0.5)))
  }
  task.grid = (coords: grid, stroke: gray.transparentize(50%))

  backend.render(task, unit-length)
}

#import "deps.typ": cetz
#import "line.typ": get-station-by-id
#import "metro.typ": get-line-by-id, get-transfer-marker-pos


#let radishom(
  metro,
  backend: "std",
  unit-length: 1cm,
  grid: auto,
  foreground: (),
  background: (),
  background-color: white,
  line-stroker: auto,
  marker-renderer: auto,
  label-renderer: auto,
  line-plugins: (),
  station-plugins: (),
) = {
  let (backend, components) = if backend == "cetz" {
    import "backends/cetz.typ" as cetz-be
    import "components/cetz.typ" as cetz-comp
    (cetz-be, dictionary(cetz-comp))
  } else if backend == "std" {
    import "backends/std.typ" as std-be
    import "components/std.typ" as std-comp
    (std-be, dictionary(std-comp))
  } else {
    panic("unknown backend: " + backend)
  }
  if line-stroker == auto {
    line-stroker = components.line-stroke
  }
  if marker-renderer == auto {
    marker-renderer = components.marker-renderer
  }
  if label-renderer == auto {
    label-renderer = components.label-renderer
  }

  // render task
  let task = (
    lines: (),
    markers: (),
    labels: (),
    background-color: background-color,
    foreground: foreground,
    background: background,
  )

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

      let transfers = metro.enabled-transfers.at(sta.id, default: none)
      let has-transfer = transfers != none
      let is-not-first-transfer = has-transfer and line.number != transfers.at(0)

      //check marker
      let hidden = sta.hidden or is-not-first-transfer

      let pos = sta.pos
      assert(pos != auto and pos.at(0) != auto, message: repr(sta))
      min-x = calc.min(min-x, pos.at(0))
      min-y = calc.min(min-y, pos.at(1))
      max-x = calc.max(max-x, pos.at(0))
      max-y = calc.max(max-y, pos.at(1))

      let marker-pos = if has-transfer {
        get-transfer-marker-pos(metro, sta.id)
      } else {
        pos
      }
      if not hidden {
        let marker = marker-renderer(line, sta, transfers)
        task.markers.push((pos: marker-pos, body: marker))
      }

      let label = label-renderer(sta)
      task.labels.push((pos: marker-pos, body: label, anchor: sta.anchor, hidden: hidden))

      for plugin in station-plugins {
        let fg = plugin(line, sta)
        if fg != none {
          task.foreground.push(fg)
        }
      }
    }

    for plugin in line-plugins {
      let fg = plugin(line)
      if fg != none {
        task.foreground.push(fg)
      }
    }
  }

  task.show-grid = grid != none
  if grid == auto or grid == none {
    grid = ((calc.floor(min-x - 0.5), calc.floor(min-y - 0.5)), (calc.ceil(max-x + 0.5), calc.ceil(max-y + 0.5)))
  }
  task.grid = (
    coords: grid,
    stroke: gray.transparentize(50%),
    heavy-stroke: gray.transparentize(40%) + 2pt,
  )

  backend.render(task, unit-length)
}

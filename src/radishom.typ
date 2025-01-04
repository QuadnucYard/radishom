#import "deps.typ": cetz
#import "metro.typ": get-transfer-label-pos
#import "utils.typ": average-pos


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

  for line in metro.lines.values() {
    if line.disabled {
      continue
    }

    let line-par = (
      number: line.number,
      color: line.color,
      index: line.index,
      segments: line.segments,
    ) // partial line used as arg

    let line-stroke = line-stroker(line-par)
    for sec in line.sections {
      if not sec.disabled {
        task.lines.push((points: sec.points, stroke: line-stroke, layer: sec.layer))
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
      assert(pos != auto and pos.at(0) != auto)
      min-x = calc.min(min-x, pos.at(0))
      min-y = calc.min(min-y, pos.at(1))
      max-x = calc.max(max-x, pos.at(0))
      max-y = calc.max(max-y, pos.at(1))

      // extract transferred lines
      let tr-lines = if has-transfer {
        for line-id in metro.transfers.at(sta.id) {
          let line = metro.lines.at(line-id)
          ((number: line.number, color: line.color, index: line.index, segments: line.segments),)
        }
      }
      let tr-stations = if has-transfer {
        for line-id in metro.transfers.at(sta.id) {
          let line = metro.lines.at(line-id)
          (line.stations.at(line.station-indexer.at(sta.id)),)
        }
      }
      let tr-positions = if has-transfer {
        for sta2 in tr-stations { (sta2.pos,) }
      }

      let marker-pos = if sta.marker-pos != auto {
        sta.marker-pos
      } else if has-transfer {
        average-pos(tr-positions)
      } else {
        pos
      }
      if sta.marker-offset != none {
        marker-pos = cetz.vector.add(marker-pos, sta.marker-offset)
      }
      if not hidden {
        let marker = marker-renderer(line-par, sta, tr-lines, tr-stations)
        task.markers.push((pos: marker-pos, body: marker))
      }

      let label = label-renderer(sta)
      let label-pos = if sta.label-pos != auto {
        sta.label-pos
      } else if has-transfer {
        get-transfer-label-pos(sta.anchor, tr-positions, marker-pos)
      } else {
        pos
      }
      if sta.label-offset != none {
        label-pos = cetz.vector.add(label-pos, sta.label-offset)
      }
      task.labels.push((pos: label-pos, body: label, anchor: sta.anchor, hidden: hidden))

      for plugin in station-plugins {
        let fg = plugin(line-par, sta)
        if fg != none {
          task.foreground.push(fg)
        }
      }
    }

    for plugin in line-plugins {
      let fg = plugin(line-par)
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

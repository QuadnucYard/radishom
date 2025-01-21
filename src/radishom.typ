#import "core/vec.typ"
#import "metro.typ": get-transfer-label-pos
#import "backends/mod.typ" as backends
#import "components/mod.typ" as components


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
  draw-disabled: false,
) = {
  let (backend, components) = if backend == "cetz" {
    (backends.use("cetz"), dictionary(components.use("cetz")))
  } else if backend == "std" {
    (backends.use("std"), dictionary(components.use("std")))
  } else {
    assert(
      line-stroker != auto and marker-renderer != auto and label-renderer != auto,
      "You should provide component renders in the custom backend",
    )
    (backend, none)
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
    if line.disabled and not draw-disabled {
      continue
    }

    let line-par = (
      id: line.id,
      color: line.color,
      index: line.index,
      segments: line.segments,
      disabled: line.disabled,
      metadata: line.metadata,
    ) // partial line used as arg

    let line-stroke = if "stroke" in line {
      line.stroke
    }
    for sec in line.sections {
      if sec.disabled and not draw-disabled {
        continue
      }
      let sec-par = (
        layer: sec.layer,
        stroke: sec.stroke,
        disabled: sec.disabled,
        metadata: sec.metadata,
      )
      let stroke = if sec.stroke != auto {
        sec.stroke
      } else if line-stroker != none {
        line-stroker(line-par, sec-par)
      } else {
        line-stroke
      }
      if stroke != none {
        task.lines.push((points: sec.points, stroke: stroke, layer: sec.layer))
      }
    }

    // draw stations
    for (j, sta) in line.stations.enumerate() {
      if sta.disabled and not draw-disabled {
        continue
      }

      let transfers = if draw-disabled {
        metro.transfers.at(sta.id, default: none)
      } else {
        metro.enabled-transfers.at(sta.id, default: none)
      }
      let has-transfer = transfers != none
      let is-not-first-transfer = has-transfer and line.id != transfers.at(0)

      //check marker
      let hidden = sta.at("hidden", default: false) or is-not-first-transfer

      let pos = sta.pos
      assert(pos != auto and pos.at(0) != auto)
      min-x = calc.min(min-x, pos.at(0))
      min-y = calc.min(min-y, pos.at(1))
      max-x = calc.max(max-x, pos.at(0))
      max-y = calc.max(max-y, pos.at(1))

      // extract transferred lines
      let tr-lines = if has-transfer {
        for line-id in transfers {
          let line = metro.lines.at(line-id)
          ((id: line.id, color: line.color, index: line.index, segments: line.segments),)
        }
      }
      let tr-stations = if has-transfer {
        for line-id in transfers {
          let line = metro.lines.at(line-id)
          (line.stations.at(line.station-indexer.at(sta.id)),)
        }
      }
      let tr-positions = if has-transfer {
        for sta2 in tr-stations { (sta2.pos,) }
      }

      let marker-pos = if "marker-pos" in sta {
        sta.marker-pos
      } else if has-transfer {
        vec.average(tr-positions)
      } else {
        pos
      }
      if "marker-offset" in sta {
        marker-pos = vec.add(marker-pos, sta.marker-offset)
      }
      if not hidden and marker-renderer != none {
        let marker = marker-renderer(line-par, sta, tr-lines, tr-stations)
        task.markers.push((pos: marker-pos, body: marker))
      }

      if not hidden and label-renderer != none {
        let label = {
          set align(if "west" in sta.anchor { left } else if "east" in sta.anchor { right } else { center })
          label-renderer(sta)
        }
        let label-pos = if "label-pos" in sta {
          sta.label-pos
        } else if has-transfer {
          get-transfer-label-pos(sta.anchor, tr-positions, marker-pos)
        } else {
          pos
        }
        if "label-offset" in sta {
          label-pos = vec.add(label-pos, sta.label-offset)
        }
        task.labels.push((pos: label-pos, body: label, anchor: sta.anchor, hidden: hidden))
      }

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


#let line-stroke(line, thickness: 6pt) = {
  let paint = if line.disabled { gray } else { line.color }
  stroke(
    paint: paint,
    thickness: thickness,
    cap: "round",
    join: "round",
  )
}

#let label-renderer(station) = {
  show: block.with(inset: (x: 0.5em, y: 0.5em))
  set par(spacing: 0.2em)
  set smartquote(enabled: false)
  set align(if "west" in station.anchor { left } else if "east" in station.anchor { right } else { center })

  [
    #text(font: "Microsoft YaHei", station.name)

    #text(size: 0.45em, font: "Source Han Sans SC", station.subname)
    // #text[(#calc.round(station.pos.at(0), digits: 1), #calc.round(station.pos.at(1), digits: 1))]
  ]
}

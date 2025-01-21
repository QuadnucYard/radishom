
#let line-stroke(line, sec, thickness: 6pt) = {
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

  [#station.name]
}

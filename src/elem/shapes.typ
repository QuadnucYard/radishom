
#let polygon(
  fill: none,
  stroke: none,
  corner-radius: 0,
  label: none,
  label-pos: none,
  ..vertices,
) = {
  (
    kind: "polygon",
    fill: fill,
    stroke: stroke,
    corner-radius: corner-radius,
    label: label,
    label-pos: label-pos,
    vertices: vertices.pos(),
  )
}

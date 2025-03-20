
/// Creates a polygon shape.
///
/// - fill (color, none): The fill color of the polygon.
/// - stroke (stroke, none): The stroke color and properties of the polygon's outline.
/// - corner-radius (float): The radius of rounded corners.
/// - label (content, none): Text label to be associated with the polygon.
/// - label-pos (vec2): Absolute position of the label .
/// - ..vertices (arguments): Variable number of points defining the polygon's vertices
/// -> dictionary
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

#import "utils.typ": make-array


#let station(
  name,
  subname,
  id: auto,
  x: auto,
  y: auto,
  dx: auto,
  dy: auto,
  r: auto,
  offset: (0, 0),
  anchor: auto,
  hidden: false,
  transfer: auto,
  marker-pos: auto,
  marker-offset: none,
  label-pos: auto,
  label-offset: none,
  pin: none,
  cfg: none,
  cfg-not: none,
  ..metadata,
) = {
  if id == auto {
    id = if type(name) == str { name } else { name.text }
  }
  (
    id: id,
    name: name,
    subname: subname,
    raw-pos: (x: x, y: y, dx: dx, dy: dy, r: r),
    offset: offset,
    anchor: anchor,
    hidden: hidden,
    transfer: transfer,
    marker-pos: marker-pos,
    marker-offset: marker-offset,
    label-pos: label-pos,
    label-offset: label-offset,
    pin: pin,
    cfg: cfg,
    cfg-not: cfg-not,
    metadata: metadata,
  )
}

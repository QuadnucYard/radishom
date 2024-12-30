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
  pin: none,
  cfg: none,
  cfg-not: none,
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
    pin: pin,
    cfg: cfg,
    cfg-not: cfg-not,
  )
}

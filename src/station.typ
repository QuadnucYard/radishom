
#let ensure-transfer(transfer) = {
  if transfer == auto {
    auto
  } else if transfer == none {
    ()
  } else if type(transfer) == str {
    (transfer,)
  } else {
    transfer
  }
}

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
    transfer: ensure-transfer(transfer),
    pin: pin,
  )
}

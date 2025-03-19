#import "../core/utils.typ": make-array


#let station(
  name,
  id: auto,
  x: auto,
  y: auto,
  dx: auto,
  dy: auto,
  r: auto,
  offset: none,
  anchor: auto,
  hidden: false,
  transfer: auto,
  branch: none,
  marker-pos: auto,
  marker-offset: none,
  label-pos: auto,
  label-offset: none,
  cfg: none,
  cfg-not: none,
  ..metadata,
) = {
  if id == auto {
    id = if type(name) == str { name } else { name.text }
  }
  let data = (
    id: id,
    name: name,
    raw-pos: (x: x, y: y, dx: dx, dy: dy, r: r),
    anchor: anchor,
    transfer: transfer,
    metadata: metadata,
  )
  if offset != none { data.offset = offset }
  if hidden != false { data.hidden = hidden }
  if branch != none { data.branch = branch }
  if marker-pos != auto { data.marker-pos = marker-pos }
  if marker-offset != none { data.marker-offset = marker-offset }
  if label-pos != auto { data.label-pos = label-pos }
  if label-offset != none { data.label-offset = label-offset }
  if cfg != none { data.cfg = cfg }
  if cfg-not != none { data.cfg-not = cfg-not }
  data
}

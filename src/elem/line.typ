#import "../core/dir.typ": resolve-target-pos
#import "../core/utils.typ": lerp


/// Creates a pin in the line.
///
/// As for arguments describing the position, you can just specify one or two. `auto` values will be inferred.
///
/// - x (auto, float): Absolute X-coordinate of the pin.
/// - y (auto, float): Absolute Y-coordinate of the pin.
/// - dx (auto, float): Relative X-offset from previous pin.
/// - dy (auto, float): Relative Y-offset from previous pin.
/// - d (auto, str): Cardinal/diagonal direction from previous pin.
///
/// - end (bool): Marks end of a section, allowing disconnected branches.
///
/// - cfg (str, none): Enabling conditions for subsequent segments.
/// - cfg-not (str, none): Disabling conditions for subsequent segments.
///
/// - layer (auto, int): Drawing layer for subsequent segments (higher layers draw on top).
/// - stroke (auto, stroke): Line style for subsequent segments.
/// - corner-radius (float, none): Radius for rounding this corner.
///
/// - ..metadata (arguments): Additional attributes of subsequent segments as named arguments.
///
/// -> dictionary
#let pin(
  x: auto,
  y: auto,
  dx: auto,
  dy: auto,
  d: auto,
  end: false,
  reverse: auto,
  cfg: auto,
  cfg-not: auto,
  layer: auto,
  stroke: auto,
  corner-radius: none,
  ..metadata,
) = {
  (
    raw-pos: (x: x, y: y, dx: dx, dy: dy, d: d),
    end: end,
    reverse: reverse,
    cfg: cfg,
    cfg-not: cfg-not,
    layer: layer,
    stroke: stroke,
    corner-radius: corner-radius,
    metadata: metadata.named(),
  )
}

/// Close the path by adding a line to the starting point or specified point.
///
/// - target (auto, str): The target station id where the loop ends.
///
/// - cfg (str, none): Enabling conditions for subsequent segments.
/// - cfg-not (str, none): Disabling conditions for subsequent segments.
///
/// - layer (auto, int): Drawing layer for subsequent segments (higher layers draw on top).
/// - stroke (auto, stroke): Line style for subsequent segments.
/// - corner-radius (float, none): Radius for rounding this corner.
///
/// - ..metadata (arguments): Additional attributes of subsequent segments as named arguments.
#let loop(
  target: auto,
  cfg: auto,
  cfg-not: auto,
  layer: auto,
  stroke: auto,
  corner-radius: none,
  ..metadata,
) = {
  (
    loop-target: target,
    end: true,
    cfg: cfg,
    cfg-not: cfg-not,
    layer: layer,
    stroke: stroke,
    corner-radius: corner-radius,
    metadata: metadata.named(),
  )
}

/// Extracts stations, sections, and segments from a sequence of points defining a metro line.
///
/// Requires at least two points to define a valid line.
/// Each point in the input array can be either a pin or a station.
///
/// Returns a dictionary containing stations, sections and segments.
///
/// - points (array): Array of point objects containing station and pin information
/// - line-id (str): Identifier for the metro line
/// -> dictionary
#let _extract-stations(points, line-id) = {
  assert(points.len() >= 2, message: "The metro line must have at least two points!")

  let last-pin = points.at(0) // resolved point
  let cur-attrs = (
    cfg: if last-pin.cfg == auto { none } else { last-pin.cfg },
    cfg-not: if last-pin.cfg-not == auto { none } else { last-pin.cfg-not },
    layer: if last-pin.layer == auto { 0 } else { last-pin.layer },
    stroke: last-pin.stroke,
    metadata: last-pin.metadata,
  )

  let sections = ()
  let section-points = ()
  let segments = ()
  let stations = ()

  let (sx, sy) = (last-pin.raw-pos.x, last-pin.raw-pos.y)
  let start-pos = (sx, sy)
  section-points.push(start-pos)
  let start-station-index = 0

  let seg-first = 1 // index of control point
  while seg-first < points.len() {
    let seg-last = seg-first
    while "id" in points.at(seg-last) {
      seg-last += 1 // skip stations
    }

    let cur-pin = points.at(seg-last)
    let (tx, ty) = if "loop-target" in cur-pin {
      if cur-pin.loop-target != auto {
        while start-station-index < stations.len() and stations.at(start-station-index).id != cur-pin.loop-target {
          start-station-index += 1
        }
        stations.at(start-station-index).pos
      } else {
        start-pos
      }
    } else {
      resolve-target-pos((x: sx, y: sy), cur-pin.raw-pos)
    }

    let angle = calc.atan2(tx - sx, ty - sy)

    let seg = (
      start: (sx, sy),
      end: (tx, ty),
      angle: angle,
      range: (start: stations.len(), end: stations.len() + seg-last - seg-first),
      cfg: cur-attrs.cfg,
      cfg-not: cur-attrs.cfg-not,
    )

    // process stations on this segment
    for sta in points.slice(seg-first, seg-last) {
      sta.segment = segments.len()

      let (x, y, r, dx, dy) = sta.remove("raw-pos")
      if x == auto and dx != auto {
        x = sx + dx
      }
      if y == auto and dy != auto {
        y = sy + dy
      }
      if r != auto {
        x = lerp(sx, tx, r)
        y = lerp(sy, ty, r)
      } else if x == auto and y != auto {
        x = (y - sy) / (ty - sy) * (tx - sx) + sx
      } else if y == auto and x != auto {
        y = (x - sx) / (tx - sx) * (ty - sy) + sy
      }
      sta.line = line-id
      sta.pos = if x == auto or y == auto { auto } else { (x, y) } // mark pos auto, handle it later
      stations.push(sta)
    }
    if "loop-target" in cur-pin {
      let i = start-station-index
      while i < stations.len() {
        stations.at(i).on-loop = true
        i += 1
      }
    }
    if cur-pin.end {
      stations.last().trunc = true // mark section truncated here
      if stations.last().pos == auto {
        stations.last().pos = seg.end
      }
    }
    segments.push(seg)

    // update current pin and cfg
    let prev-attrs = cur-attrs
    if cur-pin.cfg != auto { cur-attrs.cfg = cur-pin.cfg }
    if cur-pin.cfg-not != auto { cur-attrs.cfg-not = cur-pin.cfg-not }
    if cur-pin.layer != auto { cur-attrs.cfg-not = cur-pin.layer }
    if cur-pin.stroke != auto { cur-attrs.stroke = cur-pin.stroke }
    cur-attrs.metadata += cur-pin.metadata

    // add section point
    if not last-pin.end {
      section-points.push(if cur-pin.corner-radius == none {
        seg.end
      } else {
        (seg.end, cur-pin.corner-radius)
      })
    } else {
      start-pos = (tx, ty)
      start-station-index = stations.len()
    }

    if last-pin.end or cur-attrs != prev-attrs {
      sections.push((points: section-points, ..prev-attrs))
      section-points = (seg.end,)
    }

    last-pin = cur-pin
    sx = tx
    sy = ty
    seg-first = seg-last + 1
  }
  if section-points.len() > 0 {
    sections.push((points: section-points, ..cur-attrs))
  }

  // Set positions for terminal stations
  if stations.len() > 0 {
    if stations.first().pos == auto {
      stations.first().pos = segments.first().start
    }
    if stations.last().pos == auto {
      stations.last().pos = segments.last().end
    }
  }

  return (stations: stations, sections: sections, segments: segments)
}

/// Constructor of metro line.
///
/// Returns a `line` object with some pending properties that should be decided later in a metro system.
///
/// - id (str): Unique identifier for the line.
/// - color (color): The color of the line.
/// - index (auto, int): Index position of the line.
/// - optional (bool): Whether the line can be disabled by some features.
/// - features (dictionary): Features for the line.
/// - default-features (array): Default features for the line.
/// - stroke (auto, stroke): Custom stroke for the line.
/// - ..points (arguments): Pins and stations of the line in sequential order.
/// -> dictionary
#let line(
  id: "1",
  color: gray,
  index: auto,
  optional: false,
  features: (:),
  default-features: (),
  stroke: auto,
  ..points,
) = {
  let (stations, sections, segments) = _extract-stations(points.pos(), id)
  let station-indexer = stations.enumerate().map(((i, sta)) => (sta.id, i)).to-dict()
  let data = (
    id: id,
    color: color,
    index: index,
    sections: sections,
    segments: segments,
    stations: stations,
    station-indexer: station-indexer,
    optional: optional,
    features: features,
    default-features: default-features,
    metadata: points.named(),
  )
  if stroke != auto { data.stroke = stroke }
  data
}

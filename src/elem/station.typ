#import "../core/utils.typ": make-array

/// Constructor of metro station.
///
/// Its position can be inferred.
///
/// Returns a dictionary containing station data and properties.
///
/// - name (any): Station name or label content.
/// - id (auto, str): Unique identifier (defaults to name if string).
///
/// - x (auto, float): Absolute X coordinate.
/// - y (auto, float): Absolute Y coordinate.
/// - dx (auto, float): Relative X offset from the start of the line segment.
/// - dy (auto, float): Relative Y offset from the start of the line segment.
/// - r (auto, float): Position ratio along line segment (0.0 to 1.0).
///
/// - hidden (bool): Whether to hide the station.
/// - transfer (auto, none): Whether this station is an interchange.
/// - branch (bool): Whether this station is the start of a branch, which indicates it is not terminal.
///
/// - cfg (str, none): Enabling conditions for this station
/// - cfg-not (str, none): Disabling conditions for this station
///
/// - anchor (auto, str): Text anchor point position
/// - marker-pos (auto, vec2): Custom marker position
/// - marker-offset (vec2, none): Fine-tune marker placement
/// - label-pos (auto, vec2): Custom label position
/// - label-offset (vec2, none): Fine-tune label placement
///
/// - ..metadata (arguments): Additional station properties as named arguments.
///
/// -> dictionary
#let station(
  name,
  id: auto,
  x: auto,
  y: auto,
  dx: auto,
  dy: auto,
  r: auto,
  hidden: false,
  transfer: auto,
  branch: false,
  anchor: auto,
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

  let extra = (:)
  if hidden != false { extra.hidden = hidden }
  if marker-pos != auto { extra.marker-pos = marker-pos }
  if marker-offset != none { extra.marker-offset = marker-offset }
  if label-pos != auto { extra.label-pos = label-pos }
  if label-offset != none { extra.label-offset = label-offset }

  let data = (
    type: "Station",
    id: id,
    name: name,
    raw-pos: (x: x, y: y, dx: dx, dy: dy, r: r),
    anchor: anchor,
    transfer: transfer,
    no-transfer: transfer == none,
    metadata: metadata,
    branch: branch,
    cfg: cfg,
    cfg-not: cfg-not,
    extra: extra,
  )

  data
}

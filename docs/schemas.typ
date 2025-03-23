
#import "vendor/valkyrie.typ" as z

#let optional(ty) = {
  ty.optional = true
  ty
}

#let nullable(ty) = {
  z.either(ty, z.base-type(name: "none"))
}

#let smart(ty) = {
  z.either(z.base-type(name: "auto"), ty)
}

#let vec2 = z.tuple(name: "vec2", z.integer(), z.integer())

#let dir = z.choice(
  name: "dir",
  ("north", "south", "west", "east", "north-west", "north-east", "south-west", "south-east"),
)

#let section = z.dictionary(
  name: "section",
  (
    points: z.array(vec2),
    cfg: nullable(z.string()),
    cfg-not: nullable(z.string()),
    layer: z.number(),
    stroke: smart(z.stroke()),
    disabled: z.boolean(),
    metadata: z.dictionary((:)),
  ),
)

#let segment = z.dictionary(
  name: "segment",
  (
    start: vec2,
    end: vec2,
    angle: z.angle(),
    range: z.dictionary((start: z.integer(), end: z.integer())),
    cfg: nullable(z.string()),
    cfg-not: nullable(z.string()),
    disabled: z.boolean(),
  ),
)

#let station = z.dictionary(
  name: "station",
  (
    id: z.string(),
    name: z.any(),
    anchor: dir,
    transfer: nullable(z.base-type(name: "auto")),
    pos: vec2,
    segment: z.integer(),
    line: z.string(),
    hidden: optional(z.literals(true)),
    branch: optional(z.literals(true)),
    disabled: z.literals(true),
    marker-pos: optional(vec2),
    marker-offset: optional(vec2),
    label-pos: optional(vec2),
    label-offset: optional(vec2),
    cfg: z.string(optional: true),
    cfg-not: z.string(optional: true),
    terminal: optional(z.literals(true)),
    metadata: z.base-type(name: "arguments"),
  ),
)

#let line = z.dictionary(
  name: "line",
  (
    id: z.string(),
    color: z.color(),
    index: z.integer(),
    sections: z.array(section),
    segments: z.array(segment),
    stations: z.array(station),
    ordered-stations: z.array(z.string()),
    station-indexer: z.mapping(z.integer(), key-name: "station-id"),
    optional: z.boolean(),
    features: z.mapping(z.array(z.string())),
    default-features: z.array(z.string()),
    stroke: optional(z.stroke()),
    disabled: z.boolean(),
    metadata: z.dictionary((:)),
  ),
)

#let metro = z.dictionary(
  name: "metro",
  (
    lines: z.mapping(line, key-name: "line-id"),
    transfers: z.mapping(z.array(z.string()), key-name: "station-name"),
    features: z.mapping(z.array(z.string())),
    default-features: z.array(z.string()),
  ),
)

#let radish = z.dictionary(
  name: "radish",
  (
    lines: z.mapping(line, key-name: "line-id"),
    transfers: z.mapping(z.array(z.string()), key-name: "station-name"),
    enabled-transfers: z.mapping(z.array(z.string()), key-name: "station-name"),
    features: z.mapping(z.array(z.string())),
    default-features: z.array(z.string()),
  ),
)

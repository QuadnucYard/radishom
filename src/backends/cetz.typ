#import "../deps.typ": cetz


#let default-marker-renderer(line, station, pos: auto, has-transfer: false) = {
  if has-transfer {
    cetz.draw.circle(pos, fill: white, stroke: black + 1pt, radius: 6pt)
  } else if "terminal" in station {
    cetz.draw.circle(pos, fill: white, stroke: line.color + 1.0pt, radius: 4pt)
  } else {
    cetz.draw.circle(pos, fill: white, stroke: none, radius: 2.0pt)
  }
}

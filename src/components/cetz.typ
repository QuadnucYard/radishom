#import "../deps.typ": cetz
#import "common.typ": *


#let marker-renderer(line, station, transfers) = {
  if transfers != none {
    cetz.draw.circle((), fill: white, stroke: black + 1pt, radius: 6pt)
  } else if "terminal" in station {
    cetz.draw.circle((), fill: white, stroke: line.color + 1.0pt, radius: 4pt)
  } else {
    cetz.draw.circle((), fill: white, stroke: none, radius: 2.0pt)
  }
}

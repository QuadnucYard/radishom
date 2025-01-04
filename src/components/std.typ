#import "common.typ": *


#let primary-color = rgb("#112653")
#let normal-marker = circle(fill: white, stroke: none, radius: 2.0pt)
#let capsule-marker = rect(width: 14pt, height: 7pt, fill: white, stroke: primary-color + 1pt, radius: 3pt)
#let circle-marker = circle(fill: white, stroke: primary-color + 1pt, radius: 8pt)

#let marker-renderer(line, station, transfers) = {
  if transfers != none {
    if transfers.len() == 2 {
      let angle = station.metadata.at("marker-rotation", default: line.segments.at(station.segment).angle)
      show: rotate.with(-angle)
      capsule-marker
    } else {
      circle-marker
    }
  } else if "terminal" in station {
    circle(fill: white, stroke: line.color + 1.0pt, radius: 5pt)
  } else {
    normal-marker
  }
}

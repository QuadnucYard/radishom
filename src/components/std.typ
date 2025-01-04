#import "common.typ": *


#let primary-color = rgb("#112653")
#let normal-marker = circle(fill: white, stroke: none, radius: 2.0pt)
#let capsule-marker = rect(width: 14pt, height: 7pt, fill: white, stroke: primary-color + 1pt, radius: 4pt)
#let circle-marker = circle(fill: white, stroke: primary-color + 1pt, radius: 8pt)



#let marker-renderer(metro, line, station, transfers) = {
  import "../metro.typ": get-line-by-id, get-station-by-id, get-transfer-marker-rot

  if transfers == none {
    return if "terminal" in station {
      circle(fill: white, stroke: line.color + 1.0pt, radius: 5pt)
    } else {
      normal-marker
    }
  }
  if transfers.len() > 2 {
    return circle-marker
  }
  if transfers.len() == 2 {
    let angle = station.metadata.at("marker-rotation", default: none)
    if angle == none {
      angle = get-transfer-marker-rot(metro, station.id, transfers)
    }
    show: rotate.with(-angle)
    capsule-marker
  }
}

#import "common.typ": *
#import "../utils.typ": get-preferred-angle as _get-preferred-angle


#let primary-color = rgb("#112653")
#let normal-marker = circle(fill: white, stroke: none, radius: 2.0pt)
#let terminal-marker = color => circle(fill: white, stroke: color + 1.0pt, radius: 5pt)
#let capsule-marker = rect(width: 14pt, height: 7pt, fill: white, stroke: primary-color + 1pt, radius: 4pt)
#let circle-marker = circle(fill: white, stroke: primary-color + 1pt, radius: 8pt)


#let marker-renderer(line, station, tr-lines, tr-stations) = {
  if tr-lines == none {
    return if "terminal" in station {
      terminal-marker(line.color)
    } else {
      normal-marker
    }
  }
  if tr-lines.len() > 2 {
    return circle-marker
  }
  if tr-lines.len() == 2 {
    let angle = station.metadata.at("marker-rotation", default: none)
    if angle == none {
      let angles = for (line2, sta2) in tr-lines.zip(tr-stations) {
        (line2.segments.at(sta2.segment).angle,)
      }
      angle = _get-preferred-angle(angles)
    }
    show: rotate.with(-angle)
    capsule-marker
  }
}

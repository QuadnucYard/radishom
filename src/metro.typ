#import "deps.typ": cetz


#let _find-intersection(line, sta, tr-lines) = {
  // find stations of the same id
  let seg = line.segments.at(sta.segment)
  for line2 in tr-lines {
    if line2.number == line.number { continue }
    let sta2 = line2.stations.at(line2.station-indexer.at(sta.id))
    let seg2 = line2.segments.at(sta2.segment)
    let intersection = cetz.intersection.line-line(seg.start, seg.end, seg2.start, seg2.end)
    if intersection != none {
      intersection.pop()
      return intersection
    }
  }
  return none
}

/// Get a suitable position of the transfer marker for the given station.
#let get-transfer-marker-pos(tr-stations) = {
  let (x, y) = (0, 0)
  let cnt = 0
  for sta in tr-stations {
    let (x1, y1) = sta.pos
    x += x1
    y += y1
    cnt += 1
  }
  if cnt > 0 {
    x /= cnt
    y /= cnt
  }
  return (x, y)
}

/// Get a suitable rotation of the transfer marker for the given station.
#let get-transfer-marker-rot(station-id, tr-lines, tr-stations) = {
  let angles = for (line, sta) in tr-lines.zip(tr-stations) {
    let angle = line.segments.at(sta.segment).angle
    if angle <= -90deg { angle += 180deg }
    if angle > 90deg { angle -= 180deg }
    (angle,)
  }
  return if angles.dedup().len() == 1 {
    // parallel case
    angles.at(0) + 90deg
  } else if angles.contains(0deg) {
    // prefer horizontal
    0deg
  } else if angles.contains(90deg) {
    90deg
  } else {
    // along the direction of the first line
    angles.at(0)
  }
}

/// Get a suitable position of the label for the given station based on anchor.
#let get-transfer-label-pos(station, tr-stations, hint) = {
  let (x, y) = hint
  let anchor = station.anchor
  for sta in tr-stations {
    let (x1, y1) = sta.pos
    if "west" in anchor {
      x = calc.max(x, x1)
    } else if "east" in anchor {
      x = calc.min(x, x1)
    }
    if "south" in anchor {
      y = calc.max(y, y1)
    } else if "south" in anchor {
      y = calc.min(y, y1)
    }
  }
  return (x, y)
}

#let _resolve-transfers(lines) = {
  let station-collection = (:) // station-id -> {line-number}
  for line in lines {
    for station in line.stations {
      if station.transfer != none {
        if station.id not in station-collection {
          station-collection.insert(station.id, ())
        }
        station-collection.at(station.id).push(line.number)
      }
    }
  }
  station-collection = station-collection.pairs().filter(((k, v)) => v.len() > 1).to-dict()
  return station-collection
}

#let _resolve-stations(metro) = {
  let lines = for (i, line) in metro.lines {
    // set line index
    if line.index == auto {
      line.index = i
    }

    for (k, sta) in line.stations.enumerate() {
      // resolve station positions by intersection
      if sta.pos == auto and sta.transfer != none and sta.id in metro.transfers {
        // find transfer station with the same name on another line
        let tr-lines = for line-id in metro.transfers.at(sta.id) { (metro.lines.at(line-id),) }
        let intersection = _find-intersection(line, sta, tr-lines)
        if intersection != none {
          line.stations.at(k).pos = intersection
        }
      }
    }

    // resolve pending positions by interpolation
    for seg in line.segments {
      let start-idx = seg.range.start
      let end-idx = seg.range.end

      let last-known-index = -1
      let last-known = seg.start

      for (k, sta) in line.stations.slice(start-idx, end-idx).enumerate() {
        if sta.pos != auto {
          last-known-index = k
          last-known = sta.pos
          continue
        }
        // find next known
        let next-known = seg.end
        let next-known-index = end-idx - start-idx
        for kk in range(k + 1, end-idx - start-idx) {
          let kkk = start-idx + kk
          if line.stations.at(kkk).pos != auto {
            next-known = line.stations.at(kkk).pos
            next-known-index = kk
            break
          }
        }
        let pos = {
          let (x1, y1) = last-known
          let (x2, y2) = next-known
          let t = (k - last-known-index) / (next-known-index - last-known-index)
          (x1 + (x2 - x1) * t, y1 + (y2 - y1) * t)
        }
        line.stations.at(start-idx + k).pos = pos
      }
    }

    ((line.number, line),)
  }
  lines.to-dict()
}

#let metro(lines, features: (:), default-features: ()) = {
  let transfers = _resolve-transfers(lines)
  let mtr = (
    lines: lines.map(line => (line.number, line)).to-dict(),
    transfers: transfers,
    features: features,
    default-features: default-features,
  )
  mtr.lines = _resolve-stations(mtr)
  mtr
}

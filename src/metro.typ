#import "core/vec.typ"


/// Get a suitable position of the label for the given station based on anchor.
#let get-transfer-label-pos(anchor, tr-positions, hint) = {
  let (x, y) = hint
  for (x1, y1) in tr-positions {
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
        station-collection.at(station.id).push(line.id)
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
        let intersection = none

        let seg = line.segments.at(sta.segment)
        for line-id in metro.transfers.at(sta.id) {
          let line2 = metro.lines.at(line-id)
          if line2.id != line.id {
            let sta2 = line2.stations.at(line2.station-indexer.at(sta.id))
            let seg2 = line2.segments.at(sta2.segment)
          }
          let sta2 = line2.stations.at(line2.station-indexer.at(sta.id))
          let seg2 = line2.segments.at(sta2.segment)
          let pt = vec.intersect-line-line(seg.start, seg.end, seg2.start, seg2.end)
          if pt != none {
            intersection = pt
            break
          }
        }

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

    ((line.id, line),)
  }
  lines.to-dict()
}

#let metro(lines, features: (:), default-features: ()) = {
  let transfers = _resolve-transfers(lines)
  let mtr = (
    lines: lines.map(line => (line.id, line)).to-dict(),
    transfers: transfers,
    features: features,
    default-features: default-features,
  )
  mtr.lines = _resolve-stations(mtr)
  mtr
}

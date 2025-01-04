#import "deps.typ": cetz
#import "line.typ": get-segment-of-station, get-station-by-id


#let get-line-by-id(metro, line-num) = {
  let index = metro.line-indexer.at(line-num, default: none)
  if index != none {
    return metro.lines.at(index)
  }
}

#let get-line-station-by-id(metro, line-num, station-id) = {
  let line = get-line-by-id(metro, line-num)
  if line != none {
    get-station-by-id(line, station-id)
  } else {
    none
  }
}

#let _find-intersection(metro, line, sta) = {
  // find stations of the same id
  let seg = get-segment-of-station(line, sta)
  for line-num in metro.transfers.at(sta.id) {
    if line-num == line.number { continue }
    let line2 = get-line-by-id(metro, line-num)
    let sta2 = get-station-by-id(line2, sta.id)
    let seg2 = get-segment-of-station(line2, sta2)
    let intersection = cetz.intersection.line-line(seg.start, seg.end, seg2.start, seg2.end)
    if intersection != none {
      intersection.pop()
      return intersection
    }
  }
  return none
}

#let get-transfer-marker-pos(metro, station-id) = {
  let pos = (0, 0)
  let cnt = 0
  for line-num in metro.transfers.at(station-id) {
    let line = get-line-by-id(metro, line-num)
    if line.disabled { continue }
    let sta = get-station-by-id(line, station-id)
    if sta != none and not sta.disabled {
      pos = cetz.vector.add(pos, sta.pos)
      cnt += 1
    }
  }
  if cnt > 0 {
    pos = cetz.vector.div(pos, cnt)
  }
  return pos
}

#let get-transfer-marker-rot(metro, station-id, transfers) = {
  let angles = for line-id in transfers {
    let line = get-line-by-id(metro, line-id)
    let sta = get-station-by-id(line, station-id)
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
  (metro.lines.enumerate()).map(((i, line)) => {
    // set line index
    if line.index == auto {
      line.index = i
    }

    for (k, sta) in line.stations.enumerate() {
      // resolve station positions by intersection
      if sta.pos == auto and sta.transfer != none and sta.id in metro.transfers {
        // find transfer station with the same name on another line
        let intersection = _find-intersection(metro, line, sta)
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
        let pos = cetz.vector.lerp(
          last-known,
          next-known,
          (k - last-known-index) / (next-known-index - last-known-index),
        )
        let xx = (sta.id, pos)
        line.stations.at(start-idx + k).pos = pos
      }
    }

    return line
  })
}

#let metro(lines, features: (:), default-features: ()) = {
  let transfers = _resolve-transfers(lines)
  let line-indexer = lines.enumerate().map(((i, line)) => (line.number, i)).to-dict()
  let mtr = (
    lines: lines,
    line-indexer: line-indexer,
    transfers: transfers,
    features: features,
    default-features: default-features,
  )
  mtr.lines = _resolve-stations(mtr)
  mtr
}

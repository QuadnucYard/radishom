#import "deps.typ": cetz
#import "line.typ": get-station-by-id


#let find-intersection(lines, line, sta) = {
  if sta.transfer.len() == 0 {
    return none
  }
  // find stations of the same id
  for line2 in lines {
    if line2.number not in sta.transfer { continue }
    let sta2 = get-station-by-id(line2, sta.id)
    if sta2 != none {
      let intersection = cetz.intersection.line-line(
        sta.segment.start,
        sta.segment.end,
        sta2.segment.start,
        sta2.segment.end,
      )
      if intersection != none {
        return intersection.slice(0, 2)
      }
    }
  }
  return none
}

#let get-transfers(self, station-id, lines) = {
  let transfer = ()
  for line2 in lines {
    if line2.number == self.number { continue }
    if get-station-by-id(line2, station-id) != none {
      transfer.push(line2.number)
    }
  }
  return transfer
}

#let get-transfer-marker-pos(station-id, lines) = {
  let pos = (0, 0)
  let cnt = 0
  for line in lines {
    let sta = get-station-by-id(line, station-id)
    if sta != none {
      pos = cetz.vector.add(pos, sta.pos)
      cnt += 1
    }
  }
  if cnt > 0 {
    pos = cetz.vector.div(pos, cnt)
  }
  return pos
}

#let resolve-stations(lines) = {
  (lines.enumerate()).map(((i, line)) => {
    // set line index
    if line.index == auto {
      line.index = i
    }
    for (k, sta) in line.stations.enumerate() {
      // resolve station transfer
      if sta.transfer == auto {
        sta.transfer = get-transfers(line, sta.id, lines)
        line.stations.at(k).transfer = sta.transfer
      }
      // resolve station positions by intersection
      if sta.pos == auto {
        // find transfer station with the same name on another line
        let intersection = find-intersection(lines, line, sta)
        if intersection != none {
          sta.pos = intersection
          line.stations.at(k).pos = sta.pos
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
        line.stations.at(start-idx + k).pos = pos
      }
    }

    return line
  })
}

#let metro(lines) = {
  (lines: resolve-stations(lines))
}

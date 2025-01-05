/// Featuee-based metro instantiation.

#import "core/anchor.typ": get-best-anchor, get-best-anchor-tr
#import "feature.typ": resolve-enabled-features


#let _resolve-enabled-transfers(lines) = {
  let station-collection = (:) // station-id -> {line-number}
  for line in lines.values() {
    if line.disabled { continue }
    for station in line.stations {
      if not station.disabled and station.transfer != none {
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

#let _resolve-pending-station-attrs(metro) = {
  let lines = for (i, line) in metro.lines {
    for (k, sta) in line.stations.enumerate() {
      // set station anchor
      if sta.anchor == auto {
        line.stations.at(k).anchor = if sta.transfer == none or sta.id not in metro.enabled-transfers {
          let seg = line.segments.at(sta.segment)
          get-best-anchor(seg)
        } else {
          let tr-ctx = for line-id in metro.enabled-transfers.at(sta.id) {
            let line2 = metro.lines.at(line-id)
            let sta2 = line2.stations.at(line2.station-indexer.at(sta.id))
            ((pos: sta2.pos, seg-idx: sta2.segment, segments: line2.segments),)
          }
          get-best-anchor-tr(tr-ctx)
        }
      }
    }

    ((line.number, line),)
  }
  lines.to-dict()
}

/// Instantiate a metro system with given features.
/// It will mark lines, sections, segments, and stations disabled or not.
///
/// - metro ():
/// - features (array): Array of enabled features.
/// - default-features (bool): Whether to include default features.
/// - all-features (bool): Whether to include all features. (unimplemented)
/// - enable-all (bool): Whether to enable all elements.
/// ->
#let radish(
  metro,
  features: (),
  default-features: true,
  all-features: false,
  enable-all: false,
) = {
  let global-enabled-features = resolve-enabled-features(
    metro.features,
    if default-features { features + metro.default-features } else { features },
  )

  // we should remove unavailable transfer stations here
  for (i, line) in metro.lines {
    let enabled-features = (
      global-enabled-features
        + resolve-enabled-features(
          line.features,
          if default-features { global-enabled-features + line.default-features } else { global-enabled-features },
        )
    )

    let line-id = "L:" + line.number

    let line-disabled = not enable-all and line.optional and not enabled-features.contains(line-id)
    line.disabled = line-disabled
    if not line-disabled and not enabled-features.contains(line-id) {
      enabled-features.push(line-id)
    }

    for (j, cp) in line.sections.enumerate() {
      line.sections.at(j).disabled = (
        not enable-all and (cp.cfg != none and not enabled-features.contains(cp.cfg))
      )
    }

    for (j, seg) in line.segments.enumerate() {
      line.segments.at(j).disabled = (
        not enable-all
          and (
            seg.cfg != none and not enabled-features.contains(seg.cfg)
              or seg.cfg-not != none and enabled-features.contains(seg.cfg-not)
          )
      )
    }

    for (j, sta) in line.stations.enumerate() {
      line.stations.at(j).disabled = (
        not enable-all
          and (
            line.segments.at(sta.segment).disabled
              or sta.cfg != none and not enabled-features.contains(sta.cfg)
              or sta.cfg-not != none and enabled-features.contains(sta.cfg-not)
          )
      )
    }

    // find terminuses
    {
      let j = 0
      while j < line.stations.len() {
        while j < line.stations.len() and line.stations.at(j).disabled {
          j += 1
        }
        if j >= line.stations.len() { break }
        let first-enabled = j
        let last-enabled = j
        while j < line.stations.len() and not line.segments.at(line.stations.at(j).segment).disabled {
          last-enabled = j
          j += 1
        }
        line.stations.at(first-enabled).terminal = true
        line.stations.at(last-enabled).terminal = true
      }
    }

    metro.lines.at(i) = line
  }
  metro.enabled-transfers = _resolve-enabled-transfers(metro.lines)
  metro.lines = _resolve-pending-station-attrs(metro)

  metro
}

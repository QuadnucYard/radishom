/// Feature-based metro instantiation.

#import "../core/anchor.typ": get-best-anchor, get-best-anchor-tr
#import "../core/feature.typ": resolve-enabled-features
#import "../core/utils.typ": pick-once-elements


/// Analyzes line data to identify enabled transfer stations.
///
/// Takes a dictionary of line objects and processes them to find stations where
/// transfers between different lines are possible. A station is considered a
/// transfer point if it appears in multiple enabled lines and is not disabled.
///
/// Returns a mapping from station IDs to arrays of line IDs where transfers are possible.
/// Only includes stations that connect to multiple lines.
///
/// - lines (dictionary): Dictionary mapping line IDs to line objects.
/// -> dictionary
#let _resolve-enabled-transfers(lines) = {
  let station-collection = (:) // station-id -> {line-number}
  for line in lines.values() {
    if line.disabled { continue }
    for station in line.stations {
      if not station.disabled and station.transfer != none {
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

/// Resolves and updates pending station attributes in a metro system.
/// Returns a dictionary of updated line objects.
///
/// This function processes all stations in the system and determines their optimal
/// anchor points for labels based on line geometry and transfer connections.
/// Anchor Point Determination:
/// - For non-transfer stations:
///   Uses the angle of the line segment at the station
/// - For transfer stations:
///   Considers geometry of all connected lines to find optimal label placement
///   that avoids visual obstruction
///
/// - metro (metro): The metro system object containing lines and transfer information.
/// - consider-disabled (bool): Whether to include disabled transfers in anchor computation
///   If set to true, disabled lines will involve in the anchor computation.
/// -> dictionary
#let _resolve-pending-station-attrs(metro, consider-disabled: false) = {
  let transfers = if consider-disabled { metro.transfers } else { metro.enabled-transfers }
  let lines = for (i, line) in metro.lines {
    for (k, sta) in line.stations.enumerate() {
      // set station anchor
      if sta.anchor == auto {
        line.stations.at(k).anchor = if sta.transfer == none or sta.id not in transfers {
          let seg = line.segments.at(sta.segment)
          get-best-anchor(seg.angle)
        } else {
          let tr-ctx = for line-id in transfers.at(sta.id) {
            let line2 = metro.lines.at(line-id)
            let sta2 = line2.stations.at(line2.station-indexer.at(sta.id))
            ((pos: sta2.pos, seg-idx: sta2.segment, segments: line2.segments),)
          }
          get-best-anchor-tr(tr-ctx)
        }
      }
    }

    ((line.id, line),)
  }
  lines.to-dict()
}

/// Instantiate a metro system with given features.
/// It will mark lines, sections, segments, and stations disabled or not.
///
/// - metro (metro): A metro object.
/// - features (array): Array of enabled features.
/// - default-features (bool): Whether to include default features.
/// - all-features (bool): Whether to include all features. (unimplemented)
/// - enable-all (bool): Whether to enable all elements.
/// -> radish
#let radish(
  metro,
  features: (),
  default-features: true,
  all-features: false,
  enable-all: false,
  consider-disabled: false,
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

    let line-id = "L:" + line.id

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
              or "cfg" in sta and not enabled-features.contains(sta.cfg)
              or "cfg-not" in sta and enabled-features.contains(sta.cfg-not)
          )
      )
    }

    // find terminuses
    {
      let candidate-terminuses = ()
      let j = 0
      while j < line.stations.len() {
        while j < line.stations.len() and (not consider-disabled and line.stations.at(j).disabled) {
          j += 1
        }
        if j >= line.stations.len() { break }
        let first-enabled = j
        let last-enabled = j
        while (
          j < line.stations.len()
            and (
              consider-disabled or not line.segments.at(line.stations.at(j).segment).disabled
            )
        ) {
          last-enabled = j
          j += 1
          if "trunc" in line.stations.at(last-enabled) {
            break
          }
        }

        candidate-terminuses.push(last-enabled)
        if first-enabled != last-enabled and "branch" not in line.stations.at(first-enabled) {
          candidate-terminuses.push(first-enabled)
        }
      }

      // set stations counted once as terminuses
      for idx in pick-once-elements(candidate-terminuses) {
        line.stations.at(idx).terminal = true
      }
    }

    metro.lines.at(i) = line
  }
  metro.enabled-transfers = _resolve-enabled-transfers(metro.lines)
  metro.lines = _resolve-pending-station-attrs(metro, consider-disabled: consider-disabled)

  metro
}

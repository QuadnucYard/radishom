use indexmap::IndexMap;

use crate::{
    math::geom::intersect_line_segments,
    model::{
        line::{LineId, LineV1, LineV2},
        station::StationV1,
    },
    network::transfers::Transfers,
    util::Smart,
};

pub(crate) fn resolve_stations_final_pos<'a>(
    lines: Vec<LineV1<'a>>,
    transfers: &Transfers<'a>,
) -> IndexMap<LineId<'a>, LineV2<'a>> {
    // todo: reduce allocations
    lines
        .iter()
        .enumerate()
        .map(|(i, line)| {
            let mut stations = line.stations.clone();
            // resolve station positions by intersection
            for sta in stations.iter_mut() {
                if sta.pos.is_auto() && !sta.no_transfer && transfers.contains_key(&sta.id) {
                    // find transfer station with the same name on another line
                    let seg = line.get_segment(sta.segment).expect("segment");

                    // todo: may improve
                    if let Some(intersection) = transfers
                        .get(&sta.id)
                        .expect("station")
                        .iter()
                        .find_map(|line_id| {
                            let line2 = lines.iter().find(|line| line.id == *line_id)?;
                            let sta2 = line2.get_station(&sta.id)?;
                            let seg2 = line2.get_segment(sta2.segment)?;
                            intersect_line_segments(seg.start, seg.end, seg2.start, seg2.end)
                        })
                    {
                        sta.pos = Smart::Custom(intersection);
                    }
                }
            }

            // resolve pending positions by interpolation
            for seg in &line.segments {
                let end_idx = seg.range.end;

                let mut last_known_idx = seg.range.start;
                let mut last_known = seg.start;
                let compensate = if stations
                    .get(last_known_idx)
                    .and_then(|sta| sta.pos.custom())
                    .is_some()
                {
                    0
                } else {
                    1
                };

                // note: the known pos can be segment start/end
                while last_known_idx < end_idx {
                    while last_known_idx < end_idx
                        && let Smart::Custom(pos) = stations[last_known_idx].pos
                    {
                        last_known = pos;
                        last_known_idx += 1;
                    }
                    if last_known_idx >= end_idx {
                        break;
                    }

                    let mut next_known_idx = last_known_idx + 1;
                    while next_known_idx < end_idx && stations[next_known_idx].pos.is_auto() {
                        next_known_idx += 1;
                    }

                    let next_known = line
                        .stations
                        .get(next_known_idx)
                        .and_then(|sta| sta.pos.custom())
                        .unwrap_or(seg.end);

                    // now next_known_idx is the first known position after last_known_idx
                    let run_len = next_known_idx.saturating_sub(last_known_idx);
                    // If there are autos to interpolate
                    if run_len > 0 {
                        for (offset, sta) in stations[last_known_idx..next_known_idx]
                            .iter_mut()
                            .enumerate()
                        {
                            let t = (offset + compensate) as f32 / (run_len + compensate) as f32;
                            sta.pos = Smart::Custom(last_known.lerp(next_known, t));
                        }
                    }
                    // FIXME - problems

                    last_known_idx = next_known_idx;
                }
            }
            let station_indexer = stations
                .iter()
                .enumerate()
                .map(|(i, sta)| (sta.id.clone(), i))
                .collect();
            (
                line.id.clone(),
                LineV2 {
                    id: line.id.clone(),
                    index: line.index.unwrap_or(i as i32),

                    sections: line.sections.clone(),
                    segments: line.segments.clone(),
                    stations: stations.into_iter().map(StationV1::into).collect(),
                    ordered_stations: line.ordered_stations.clone(),
                    station_indexer,

                    optional: line.optional,
                    features: line.features.clone(),
                    default_features: line.default_features.clone(),

                    disabled: false,
                },
            )
        })
        .collect()
}

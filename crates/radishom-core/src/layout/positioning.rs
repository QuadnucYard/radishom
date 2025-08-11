use ecow::EcoString;
use indexmap::IndexMap;

use crate::{
    feature::FeatureCondition,
    math::{FloatExt, Vec2, geom::intersect_line_segments},
    model::{
        line::{LineComponent, LineId, LineV1, LineV2, Pin, Section, Segment},
        station::{StationId, StationV1},
    },
    network::transfers::Transfers,
    util::Smart,
};

pub(crate) struct StationResolution {
    pub stations: Vec<StationV1>,
    pub ordered_stations: Vec<StationId>,
    pub sections: Vec<Section>,
    pub segments: Vec<Segment>,
}

pub(crate) fn extract_stations(
    components: Vec<LineComponent>,
    line_id: LineId,
) -> StationResolution {
    let Some(LineComponent::Pin(last_pin)) = components.first() else {
        panic!("The points must start with a pin!");
    };
    let mut last_pin = last_pin;
    let mut cur_attrs = AccumulatedAttrs::from_pin(last_pin);

    let mut stations: Vec<StationV1> = vec![];
    let mut section_points = vec![];
    let mut segments = Vec::<Segment>::new();
    let mut sections = vec![];
    let mut ordered_stations = vec![];

    let mut current_pos = Vec2::new(
        last_pin.raw_pos.as_ref().unwrap().x.unwrap_or_default(),
        last_pin.raw_pos.as_ref().unwrap().y.unwrap_or_default(),
    );
    let mut start_pos = current_pos;
    section_points.push((start_pos, None));
    let mut start_station_index = 0;
    let mut reverse_first = 0;

    let mut seg_first = 1; // Current range of stations in `points`: [`seg-first`, `seg-last`)
    while seg_first < components.len() {
        let mut seg_last = seg_first;
        while matches!(components[seg_last], LineComponent::Station(_)) {
            seg_last += 1; // skip stations
        }
        // Now seg_last points to the next pin

        let LineComponent::Pin(cur_pin) = &components[seg_last] else {
            panic!("expect pin");
        };
        let target_pos = match cur_pin.loop_target.as_ref() {
            Some(Smart::Custom(loop_target)) => {
                while start_station_index < stations.len()
                    && stations[start_station_index].id != *loop_target
                {
                    start_station_index += 1;
                }
                stations[start_station_index].pos.unwrap_or_default() // todo: unwrap
            }
            Some(Smart::Auto) => start_pos,
            None => cur_pin.raw_pos.as_ref().unwrap().resolve_from(current_pos),
        };

        let angle = (target_pos - current_pos).angle();

        // add new segment. should be performed before processing stations
        let seg = Segment {
            start: current_pos,
            end: target_pos,
            angle,
            range: stations.len()..stations.len() + (seg_last - seg_first),
            cfg: FeatureCondition {
                required: cur_attrs.cfg.clone(),
                excluded: cur_attrs.cfg_not.clone(),
            },
            disabled: false,
        };

        // process stations on this segment
        for comp in components[seg_first..seg_last].iter() {
            let LineComponent::Station(sta) = comp else {
                continue;
            };

            let raw_pos = &sta.raw_pos;

            let x = match (raw_pos.x, raw_pos.dx, raw_pos.r, raw_pos.y) {
                (Smart::Custom(x), _, _, _) => Smart::Custom(x),
                (_, Smart::Custom(dx), _, _) => Smart::Custom(current_pos.x + dx),
                (_, _, Smart::Custom(r), _) => Smart::Custom(current_pos.x.lerp(target_pos.x, r)),
                (_, _, _, Smart::Custom(y)) => {
                    Smart::Custom(current_pos.interpolate_x_for_y(target_pos, y))
                }
                _ => Smart::Auto,
            };
            let y = match (raw_pos.y, raw_pos.dy, raw_pos.r, raw_pos.x) {
                (Smart::Custom(y), _, _, _) => Smart::Custom(y),
                (_, Smart::Custom(dy), _, _) => Smart::Custom(current_pos.y + dy),
                (_, _, Smart::Custom(r), _) => Smart::Custom(current_pos.y.lerp(target_pos.y, r)),
                (_, _, _, Smart::Custom(x)) => {
                    Smart::Custom(current_pos.interpolate_y_for_x(target_pos, x))
                }
                _ => Smart::Auto,
            };
            let sta_pos = match (x, y) {
                (Smart::Custom(x), Smart::Custom(y)) => Smart::Custom(Vec2::new(x, y)),
                _ => Smart::Auto,
            };

            stations.push(StationV1 {
                id: sta.id.clone(),

                line: line_id.clone(),
                segment: segments.len(),

                pos: sta_pos,
                branch: sta.branch,
                on_loop: false,
                trunc: false,
                no_transfer: sta.no_transfer,

                cfg: FeatureCondition {
                    required: sta.cfg.clone(),
                    excluded: sta.cfg_not.clone(),
                },

                anchor: sta.anchor,
            });
            ordered_stations.push(sta.id.clone());
        }

        if cur_pin.loop_target.is_some() {
            for sta in stations[start_station_index..].iter_mut() {
                sta.on_loop = true;
            }
        }

        if cur_pin.end
            && let Some(last_sta) = stations.last_mut()
        {
            last_sta.trunc = true; // mark section truncated here
            if last_sta.segment == segments.len() && last_sta.pos.is_auto() {
                last_sta.pos = Smart::Custom(target_pos);
            }
        }

        segments.push(seg);

        let prev_attrs = cur_attrs.clone();
        cur_attrs = cur_attrs.renewed(cur_pin);

        // add section point
        if !last_pin.end {
            section_points.push((target_pos, cur_pin.corner_radius));
        } else {
            start_pos = target_pos;
            start_station_index = stations.len();
        }

        if last_pin.end || cur_attrs != prev_attrs {
            sections.push(Section {
                points: std::mem::replace(&mut section_points, vec![(target_pos, None)]),
                cut: seg_last,

                reversed: cur_attrs.reversed,
                cfg: FeatureCondition {
                    required: cur_attrs.cfg.clone(),
                    excluded: cur_attrs.cfg_not.clone(),
                },
                layer: cur_attrs.layer,

                disabled: false,
            });

            // handle reversal
            if !cur_attrs.reversed {
                if prev_attrs.reversed {
                    ordered_stations[reverse_first..].reverse();
                }
                reverse_first = ordered_stations.len();
            }
            // reverse all stations before
            if last_pin.reverse_before {
                ordered_stations.reverse();
            }
        }

        last_pin = cur_pin;
        current_pos = target_pos;
        seg_first = seg_last + 1;
    }

    if cur_attrs.reversed {
        ordered_stations[reverse_first..].reverse();
    }
    if last_pin.reverse_before {
        ordered_stations.reverse();
    }

    if !section_points.is_empty() {
        sections.push(Section {
            points: section_points,
            cut: seg_first,

            reversed: cur_attrs.reversed,
            cfg: FeatureCondition {
                required: cur_attrs.cfg.clone(),
                excluded: cur_attrs.cfg_not.clone(),
            },
            layer: cur_attrs.layer,

            disabled: false,
        });
    }

    // Set positions for terminal stations
    if let Some((first_sta, first_seg)) = stations.first_mut().zip(segments.first())
        && first_sta.pos.is_auto()
    {
        first_sta.pos = Smart::Custom(first_seg.start);
    }
    if let Some((last_sta, last_seg)) = stations.last_mut().zip(segments.last())
        && last_sta.pos.is_auto()
    {
        last_sta.pos = Smart::Custom(last_seg.end);
    }

    StationResolution {
        stations,
        ordered_stations,
        sections,
        segments,
    }
}

pub(crate) fn resolve_stations_final_pos(
    lines: Vec<LineV1>,
    transfers: &Transfers,
) -> IndexMap<LineId, LineV2> {
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
                    for (k, sta) in stations[last_known_idx..next_known_idx]
                        .iter_mut()
                        .enumerate()
                    {
                        sta.pos = Smart::Custom(last_known.lerp(
                            next_known,
                            (k - last_known_idx + compensate) as f32
                                / (next_known_idx - last_known_idx + compensate) as f32,
                        ));
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

#[derive(Clone, PartialEq, Eq)]
struct AccumulatedAttrs {
    pub reversed: bool,
    pub cfg: Option<EcoString>,
    pub cfg_not: Option<EcoString>,
    pub layer: i32,
    pub stroke: Smart<EcoString>, // stub for comparison
}

impl AccumulatedAttrs {
    pub fn from_pin(pin: &Pin) -> Self {
        Self {
            reversed: pin.reversed.unwrap_or(false),
            cfg: pin.cfg.clone().unwrap_or(None),
            cfg_not: pin.cfg_not.clone().unwrap_or(None),
            layer: pin.layer.unwrap_or(0),
            stroke: pin.stroke.clone(),
        }
    }

    pub fn renewed(&self, pin: &Pin) -> Self {
        Self {
            reversed: pin.reversed.unwrap_or(self.reversed),
            cfg: pin.cfg.clone().unwrap_or_else(|| self.cfg.clone()),
            cfg_not: pin.cfg_not.clone().unwrap_or_else(|| self.cfg_not.clone()),
            layer: pin.layer.unwrap_or(self.layer),
            stroke: pin.stroke.clone().or_else(|| self.stroke.clone()),
        }
    }
}

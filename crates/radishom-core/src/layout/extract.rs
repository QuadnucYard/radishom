use ecow::EcoString;

use crate::{
    feature::{Feature, FeatureCondition},
    math::Vec2,
    model::{
        line::{LineComponent, LineId, Pin, Section, Segment},
        station::{StationId, StationV1},
    },
    util::Smart,
};

pub struct StationResolution {
    pub stations: Vec<StationV1>,
    pub ordered_stations: Vec<StationId>,
    pub sections: Vec<Section>,
    pub segments: Vec<Segment>,
}

pub fn extract_stations(components: Vec<LineComponent>, line_id: LineId) -> StationResolution {
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
                // TODO: loop_target handling: if a specified loop_target station id is never found, indexing stations[start_station_index] will panic. Add a check to fall back to start_pos or error out gracefully.
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

            let sta_pos = sta.raw_pos.resolve_between(current_pos, target_pos);

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

#[derive(Clone, PartialEq, Eq)]
struct AccumulatedAttrs {
    pub reversed: bool,
    pub cfg: Option<Feature>,
    pub cfg_not: Option<Feature>,
    pub layer: i32,
    pub stroke: Smart<EcoString>, // stub for comparison
}

impl AccumulatedAttrs {
    pub fn from_pin(pin: &Pin) -> Self {
        Self {
            reversed: pin.reversed.unwrap_or(false),
            cfg: match pin.cfg.as_ref() {
                Some(Smart::Auto) => None,
                Some(Smart::Custom(t)) => Some(t.clone()),
                None => None,
            },
            cfg_not: match pin.cfg_not.as_ref() {
                Some(Smart::Auto) => None,
                Some(Smart::Custom(t)) => Some(t.clone()),
                None => None,
            },
            layer: pin.layer.unwrap_or(0),
            stroke: pin.stroke.clone(),
        }
    }

    pub fn renewed(&self, pin: &Pin) -> Self {
        Self {
            reversed: pin.reversed.unwrap_or(self.reversed),
            cfg: match pin.cfg.as_ref() {
                Some(Smart::Auto) => self.cfg.clone(),
                Some(Smart::Custom(t)) => Some(t.clone()),
                None => None,
            },
            cfg_not: match pin.cfg_not.as_ref() {
                Some(Smart::Auto) => self.cfg.clone(),
                Some(Smart::Custom(t)) => Some(t.clone()),
                None => None,
            },
            layer: pin.layer.unwrap_or(self.layer),
            stroke: pin.stroke.clone().or_else(|| self.stroke.clone()),
        }
    }
}

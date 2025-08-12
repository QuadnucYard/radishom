use std::{collections::BTreeMap, ops::Range};

use ecow::EcoString;
use serde_derive::{Deserialize, Serialize};

use crate::{
    feature::{Feature, FeatureCondition, FeatureMap, FeatureVec},
    layout::{WalkPos, extract::extract_stations},
    math::Vec2,
    model::station::{StationId, StationV0, StationV1, StationV2},
    util::Smart,
};

#[derive(Debug, Clone, Eq, PartialEq, Hash, Serialize, Deserialize)]
pub struct LineId(EcoString);

impl std::fmt::Display for LineId {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        self.0.fmt(f)
    }
}

// ===

#[derive(Deserialize)]
#[serde(rename_all = "kebab-case")]
pub struct LineV0 {
    pub id: LineId,
    pub index: Smart<i32>,
    pub optional: bool,
    pub features: FeatureMap,
    pub default_features: FeatureVec,

    pub components: Vec<LineComponent>,
}

#[derive(Deserialize)]
#[serde(tag = "type")]
pub enum LineComponent {
    Pin(Pin),
    Station(StationV0),
}

#[derive(Deserialize)]
#[serde(rename_all = "kebab-case")]
pub struct Pin {
    pub raw_pos: Option<WalkPos>,

    pub end: bool,
    #[serde(default)]
    pub loop_target: Option<Smart<StationId>>,
    pub reversed: Smart<bool>,
    pub reverse_before: bool,

    // pub cfg: Smart<Option<Feature>>,
    // pub cfg_not: Smart<Option<Feature>>,
    pub cfg: Option<Smart<Feature>>,
    pub cfg_not: Option<Smart<Feature>>,

    pub layer: Smart<i32>,
    pub corner_radius: Option<f32>,
    pub stroke: Smart<EcoString>, // stub for comparison
}

// ===

pub struct LineV1 {
    pub id: LineId,
    pub index: Smart<i32>,

    pub sections: Vec<Section>,
    pub segments: Vec<Segment>,
    pub stations: Vec<StationV1>,
    pub ordered_stations: Vec<StationId>,
    pub station_indexer: BTreeMap<StationId, usize>,

    pub optional: bool,
    pub features: FeatureMap,
    pub default_features: FeatureVec,
}

#[derive(Serialize)]
#[serde(rename_all = "kebab-case")]
pub struct LineV2 {
    pub id: LineId,
    pub index: i32,

    pub sections: Vec<Section>,
    pub segments: Vec<Segment>,
    pub stations: Vec<StationV2>,
    pub ordered_stations: Vec<StationId>,
    pub station_indexer: BTreeMap<StationId, usize>,

    pub optional: bool,
    pub features: FeatureMap,
    pub default_features: FeatureVec,

    pub disabled: bool,
}

#[derive(Clone, Serialize, Deserialize)]
#[serde(rename_all = "kebab-case")]
pub struct Section {
    pub points: Vec<(Vec2, Option<f32>)>, // (point, corner_radius)
    pub cut: usize,

    pub reversed: bool,
    pub layer: i32,
    pub cfg: FeatureCondition,

    pub disabled: bool,
}

#[derive(Clone, Serialize, Deserialize)]
#[serde(rename_all = "kebab-case")]
pub struct Segment {
    pub start: Vec2,
    pub end: Vec2,
    pub angle: f32,
    pub range: Range<usize>,
    pub cfg: FeatureCondition,

    pub disabled: bool,
}

impl LineV0 {
    pub fn resolve(self) -> LineV1 {
        let res = extract_stations(self.components, self.id.clone());
        let station_indexer = res
            .stations
            .iter()
            .enumerate()
            .map(|(i, sta)| (sta.id.clone(), i))
            .collect();

        LineV1 {
            id: self.id,
            index: self.index,
            sections: res.sections,
            segments: res.segments,
            stations: res.stations,
            ordered_stations: res.ordered_stations,
            station_indexer,
            optional: self.optional,
            features: self.features,
            default_features: self.default_features,
        }
    }
}

impl LineV1 {
    pub fn get_segment(&self, segment_index: usize) -> Option<&Segment> {
        self.segments.get(segment_index)
    }

    pub fn get_station(&self, station_id: &StationId) -> Option<&StationV1> {
        self.station_indexer
            .get(station_id)
            .and_then(|idx| self.stations.get(*idx))
    }
}

impl LineV2 {
    pub fn get_station(&self, station_id: &StationId) -> Option<&StationV2> {
        self.station_indexer
            .get(station_id)
            .and_then(|idx| self.stations.get(*idx))
    }

    pub fn mark_terminuses(&mut self, consider_disabled: bool) {
        let mut candidate_terminuses = Vec::new();
        let mut j = 0;
        while j < self.stations.len() {
            while j < self.stations.len() && (!consider_disabled && self.stations[j].disabled) {
                j += 1;
            }
            if j >= self.stations.len() {
                break;
            }
            let first_enabled = j;
            let mut last_enabled = j;
            // advance through a run of stations whose segments are considered enabled
            let mut advanced = false;
            while j < self.stations.len()
                && (consider_disabled || !self.segments[self.stations[j].segment].disabled)
            {
                last_enabled = j;
                j += 1;
                advanced = true;
                if self.stations[last_enabled].trunc {
                    break;
                }
            }
            // if no progress was made (e.g., segment disabled while consider_disabled == false),
            // advance j by one to avoid getting stuck on the same element
            if !advanced {
                j += 1;
            }

            candidate_terminuses.push(last_enabled);
            if first_enabled != last_enabled && !self.stations[first_enabled].branch {
                candidate_terminuses.push(first_enabled);
            }
        }

        // set stations counted once as terminuses
        let unique_terminuses = candidate_terminuses
            .iter()
            .filter(|&&x| candidate_terminuses.iter().filter(|&&y| y == x).count() == 1);
        for &idx in unique_terminuses {
            if !self.stations[idx].on_loop {
                self.stations[idx].terminal = true;
            }
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_deserialize_pin() {
        let json_str = r#"
        {
            "raw-pos": {
                "x": 0,
                "y": 0,
                "dx": "auto",
                "dy": "auto",
                "d": "auto"
            },
            "end": false,
            "reversed": "auto",
            "reverse-before": false,
            "cfg": "auto",
            "cfg-not": "auto",
            "layer": "auto",
            "stroke": "auto",
            "corner-radius": null,
            "metadata": {}
        }
        "#;
        let _pin: Pin = serde_json::from_str(json_str).unwrap();
    }

    #[test]
    fn test_deserialize_station() {
        let json_str = r#"
        {
            "id": "1s",
            "name": {
                "func": "text",
                "text": "1s"
            },
            "raw-pos": {
                "x": "auto",
                "y": "auto",
                "dx": "auto",
                "dy": "auto",
                "r": "auto"
            },
            "anchor": "auto",
            "transfer": "auto",
            "no-transfer": false,
            "metadata": "arguments()"
        }
        "#;
        let _pin: StationV0 = serde_json::from_str(json_str).unwrap();
    }
}

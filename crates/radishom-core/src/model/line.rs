use std::{collections::HashMap, ops::Range};

use ecow::EcoString;
use serde_derive::{Deserialize, Serialize};

use crate::{
    layout::{WalkPos, positioning::extract_stations},
    math::Vec2,
    model::{
        Smart,
        station::{StationId, StationV0, StationV1, StationV2},
    },
};

#[derive(Clone, Eq, PartialEq, Hash, Debug, Serialize, Deserialize)]
pub struct LineId(EcoString);

// ===

#[derive(Deserialize)]
#[serde(rename_all = "kebab-case")]
pub struct LineV0 {
    pub id: LineId,
    pub index: Smart<i32>,
    pub optional: bool,
    pub features: HashMap<EcoString, Vec<EcoString>>,
    pub default_features: Vec<EcoString>,

    pub components: Vec<LineComponent>,
}

#[derive(Deserialize)]
#[serde(untagged)]
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

    pub cfg: Smart<Option<EcoString>>,
    pub cfg_not: Smart<Option<EcoString>>,

    pub layer: Smart<i32>,
    pub corner_radius: Option<f32>,
    pub stroke: Smart<EcoString>, // stub for comparison
}

// ===

#[derive(Serialize, Deserialize)]
#[serde(rename_all = "kebab-case")]
pub struct LineV1 {
    pub id: LineId,
    pub index: Smart<i32>,

    pub sections: Vec<Section>,
    pub segments: Vec<Segment>,
    pub stations: Vec<StationV1>,
    pub ordered_stations: Vec<StationId>,
    pub station_indexer: HashMap<StationId, usize>,

    pub optional: bool,
    pub features: HashMap<EcoString, Vec<EcoString>>,
    pub default_features: Vec<EcoString>,
}

#[derive(Clone, Serialize, Deserialize)]
#[serde(rename_all = "kebab-case")]
pub struct Section {
    pub points: Vec<(Vec2, Option<f32>)>, // (point, corner_radius)
    pub cut: usize,
    #[serde(flatten)]
    pub attrs: AccumulatedAttrs,
}

#[derive(Clone, Serialize, Deserialize)]
#[serde(rename_all = "kebab-case")]
pub struct Segment {
    pub start: Vec2,
    pub end: Vec2,
    pub angle: f32,
    pub range: Range<usize>,
    pub cfg: Option<EcoString>,
    pub cfg_not: Option<EcoString>,
}

#[derive(Clone, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "kebab-case")]
pub struct AccumulatedAttrs {
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

#[derive(Serialize)]
#[serde(rename_all = "kebab-case")]
pub struct LineV2 {
    pub id: LineId,
    pub index: i32,

    pub sections: Vec<Section>,
    pub segments: Vec<Segment>,
    pub stations: Vec<StationV2>,
    pub ordered_stations: Vec<StationId>,
    pub station_indexer: HashMap<StationId, usize>,

    pub optional: bool,
    pub features: HashMap<EcoString, Vec<EcoString>>,
    pub default_features: Vec<EcoString>,
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

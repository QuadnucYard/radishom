use ecow::EcoString;
use serde_derive::{Deserialize, Serialize};

use crate::{feature::FeatureCondition, layout::Dir, math::Vec2, model::line::LineId, util::Smart};

#[derive(Clone, Eq, PartialEq, Hash, Debug, PartialOrd, Ord, Serialize, Deserialize)]
pub struct StationId(EcoString);

#[derive(Deserialize)]
#[serde(rename_all = "kebab-case")]
pub struct StationV0 {
    pub id: StationId,

    pub raw_pos: RawStationPos,
    pub branch: bool,
    pub no_transfer: bool,
    pub anchor: Smart<Dir>,

    pub cfg: Option<EcoString>,
    pub cfg_not: Option<EcoString>,
}

#[derive(Deserialize)]
pub struct RawStationPos {
    pub x: Smart<f32>,
    pub y: Smart<f32>,
    pub dx: Smart<f32>,
    pub dy: Smart<f32>,
    pub r: Smart<f32>,
}

#[derive(Clone)]
pub struct StationV1 {
    pub id: StationId,

    pub line: LineId,
    pub segment: usize,

    pub pos: Smart<Vec2>,
    pub branch: bool,
    pub on_loop: bool,
    pub trunc: bool,
    pub no_transfer: bool,
    pub anchor: Smart<Dir>,

    pub cfg: FeatureCondition,
}

#[derive(Serialize)]
#[serde(rename_all = "kebab-case")]
pub struct StationV2 {
    pub id: StationId,

    pub line: LineId,
    pub segment: usize,

    pub pos: Vec2,
    pub branch: bool,
    pub on_loop: bool,
    pub trunc: bool,
    pub no_transfer: bool,
    pub anchor: Smart<Dir>,

    pub cfg: FeatureCondition,

    pub disabled: bool,
    pub terminal: bool,
}

impl From<StationV1> for StationV2 {
    fn from(value: StationV1) -> Self {
        Self {
            id: value.id,
            line: value.line,
            segment: value.segment,

            pos: value.pos.unwrap_or_default(),
            branch: value.branch,
            on_loop: value.on_loop,
            trunc: value.trunc,
            no_transfer: value.no_transfer,

            cfg: value.cfg.clone(),
            anchor: value.anchor,

            disabled: false,
            terminal: false,
        }
    }
}

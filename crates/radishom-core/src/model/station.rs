use ecow::EcoString;
use serde_derive::{Deserialize, Serialize};

use crate::{
    layout::Dir,
    math::Vec2,
    model::{Smart, line::LineId},
};

#[derive(Clone, Eq, PartialEq, Hash, Debug, PartialOrd, Ord, Serialize, Deserialize)]
pub struct StationId(EcoString);

#[derive(Deserialize)]
#[serde(rename_all = "kebab-case")]
pub struct StationV0 {
    pub id: StationId,
    pub raw_pos: RawStationPos,
    pub no_transfer: bool,

    pub cfg: Option<EcoString>,
    pub cfg_not: Option<EcoString>,

    pub anchor: Smart<Dir>,
}

#[derive(Deserialize)]
pub struct RawStationPos {
    pub x: Smart<f32>,
    pub y: Smart<f32>,
    pub dx: Smart<f32>,
    pub dy: Smart<f32>,
    pub r: Smart<f32>,
}

#[derive(Clone, Serialize, Deserialize)]
#[serde(rename_all = "kebab-case")]
pub struct StationV1 {
    pub id: StationId,

    pub line: LineId,
    pub segment: usize,

    pub pos: Smart<Vec2>,
    pub on_loop: bool,
    pub trunc: bool,
    pub no_transfer: bool,

    pub cfg: Option<EcoString>,
    pub cfg_not: Option<EcoString>,

    pub anchor: Smart<Dir>,
}

#[derive(Serialize)]
#[serde(rename_all = "kebab-case")]
pub struct StationV2 {
    pub id: StationId,

    pub line: LineId,
    pub segment: usize,

    pub pos: Vec2,
    pub on_loop: bool,
    pub trunc: bool,
    pub no_transfer: bool,

    pub cfg: Option<EcoString>,
    pub cfg_not: Option<EcoString>,

    pub anchor: Smart<Dir>,
}

impl From<StationV1> for StationV2 {
    fn from(value: StationV1) -> Self {
        Self {
            id: value.id,
            line: value.line,
            segment: value.segment,
            pos: value.pos.unwrap_or_default(),
            on_loop: value.on_loop,
            trunc: value.trunc,
            no_transfer: value.no_transfer,
            cfg: value.cfg,
            cfg_not: value.cfg_not,
            anchor: value.anchor,
        }
    }
}

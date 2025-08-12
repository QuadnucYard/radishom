use std::borrow::Cow;

use serde_derive::{Deserialize, Serialize};

use crate::{
    feature::FeatureCondition,
    layout::Dir,
    math::{FloatExt, Vec2},
    model::line::LineId,
    util::Smart,
};

#[derive(Clone, Eq, PartialEq, Hash, Debug, PartialOrd, Ord, Serialize, Deserialize)]
pub struct StationId<'a>(Cow<'a, str>);

#[derive(Deserialize)]
#[serde(rename_all = "kebab-case")]
pub struct StationV0<'a> {
    pub id: StationId<'a>,

    pub raw_pos: RawStationPos,
    pub branch: bool,
    pub no_transfer: bool,
    pub anchor: Smart<Dir>,

    pub cfg: Option<Cow<'a, str>>,
    pub cfg_not: Option<Cow<'a, str>>,
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
pub struct StationV1<'a> {
    pub id: StationId<'a>,

    pub line: LineId<'a>,
    pub segment: usize,

    pub pos: Smart<Vec2>,
    pub branch: bool,
    pub on_loop: bool,
    pub trunc: bool,
    pub no_transfer: bool,
    pub anchor: Smart<Dir>,

    pub cfg: FeatureCondition<'a>,
}

#[derive(Serialize)]
#[serde(rename_all = "kebab-case")]
pub struct StationV2<'a> {
    pub id: StationId<'a>,

    pub line: LineId<'a>,
    pub segment: usize,

    pub pos: Vec2,
    pub branch: bool,
    pub on_loop: bool,
    pub trunc: bool,
    pub no_transfer: bool,
    pub anchor: Smart<Dir>,

    pub cfg: FeatureCondition<'a>,

    pub disabled: bool,
    pub terminal: bool,
}

impl<'a> From<StationV1<'a>> for StationV2<'a> {
    fn from(value: StationV1<'a>) -> Self {
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

impl RawStationPos {
    pub fn resolve_between(&self, current_pos: Vec2, target_pos: Vec2) -> Smart<Vec2> {
        let x = match (self.x, self.dx, self.r, self.y) {
            (Smart::Custom(x), _, _, _) => Smart::Custom(x),
            (_, Smart::Custom(dx), _, _) => Smart::Custom(current_pos.x + dx),
            (_, _, Smart::Custom(r), _) => Smart::Custom(current_pos.x.lerp(target_pos.x, r)),
            (_, _, _, Smart::Custom(y)) => {
                Smart::Custom(current_pos.interpolate_x_for_y(target_pos, y))
            }
            _ => Smart::Auto,
        };
        let y = match (self.y, self.dy, self.r, self.x) {
            (Smart::Custom(y), _, _, _) => Smart::Custom(y),
            (_, Smart::Custom(dy), _, _) => Smart::Custom(current_pos.y + dy),
            (_, _, Smart::Custom(r), _) => Smart::Custom(current_pos.y.lerp(target_pos.y, r)),
            (_, _, _, Smart::Custom(x)) => {
                Smart::Custom(current_pos.interpolate_y_for_x(target_pos, x))
            }
            _ => Smart::Auto,
        };
        match (x, y) {
            (Smart::Custom(x), Smart::Custom(y)) => Smart::Custom(Vec2::new(x, y)),
            _ => Smart::Auto,
        }
    }
}

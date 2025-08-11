use serde_derive::{Deserialize, Serialize};

use crate::{math::Vec2, util::Smart};

#[derive(Debug, Copy, Clone, Eq, PartialEq, Hash, Serialize, Deserialize)]
pub enum Dir {
    N,
    S,
    W,
    E,
    NW,
    NE,
    SW,
    SE,
}

#[derive(Deserialize)]
pub struct WalkPos {
    pub x: Smart<f32>,
    pub y: Smart<f32>,
    pub dx: Smart<f32>,
    pub dy: Smart<f32>,
    pub d: Smart<Dir>,
}

impl WalkPos {
    pub fn resolve_from(&self, origin: Vec2) -> Vec2 {
        resolve_target_pos(origin, self)
    }
}

fn resolve_target_pos(origin: Vec2, target: &WalkPos) -> Vec2 {
    let x = match (target.x, target.d) {
        (Smart::Custom(x), _) => x,
        (Smart::Auto, Smart::Auto) => origin.x + target.dx.unwrap_or(0.0),
        (Smart::Auto, Smart::Custom(dir)) => match dir {
            Dir::E | Dir::W => origin.x + target.dx.unwrap_or(0.0),
            Dir::N | Dir::S => origin.x,
            Dir::NE | Dir::SW => {
                let dx = match (target.dx, target.dy) {
                    (Smart::Custom(dx), _) => dx,
                    (_, Smart::Custom(dy)) => dy,
                    (Smart::Auto, Smart::Auto) => target.y.unwrap_or_default() - origin.y,
                };
                origin.x + dx
            }
            Dir::SE | Dir::NW => {
                let dx = match (target.dx, target.dy) {
                    (Smart::Custom(dx), _) => dx,
                    (_, Smart::Custom(dy)) => -dy,
                    (Smart::Auto, Smart::Auto) => -(target.y.unwrap_or_default() - origin.y),
                };
                origin.x + dx
            }
        },
    };

    let y = match (target.y, target.d) {
        (Smart::Custom(y), _) => y,
        (Smart::Auto, Smart::Auto) => origin.y + target.dy.unwrap_or(0.0),
        (Smart::Auto, Smart::Custom(dir)) => match dir {
            Dir::N | Dir::S => origin.y + target.dx.unwrap_or(0.0),
            Dir::E | Dir::W => origin.y,
            Dir::NE | Dir::SW => {
                let dy = match (target.dy, target.dx) {
                    (Smart::Custom(dy), _) => dy,
                    (_, Smart::Custom(dx)) => dx,
                    (Smart::Auto, Smart::Auto) => target.x.unwrap_or_default() - origin.x,
                };
                origin.y + dy
            }
            Dir::SE | Dir::NW => {
                let dy = match (target.dy, target.dx) {
                    (Smart::Custom(dy), _) => dy,
                    (_, Smart::Custom(dx)) => -dx,
                    (Smart::Auto, Smart::Auto) => -(target.x.unwrap_or_default() - origin.x),
                };
                origin.y + dy
            }
        },
    };

    Vec2::new(x, y)
}

use std::f32::consts::PI;

use indexmap::IndexMap;
use itertools::Itertools;

use crate::{
    layout::Dir,
    model::{
        line::{LineId, LineV2},
        station::StationId,
    },
};

/// Directions in 45° increments, starting from West and going clockwise.
const ANCHORS: [Dir; 8] = [
    Dir::W,
    Dir::SW,
    Dir::S,
    Dir::SE,
    Dir::E,
    Dir::NE,
    Dir::N,
    Dir::NW,
];

/// Returns the best anchor direction for a single line segment based on its angle.
pub fn get_best_anchor(angle: f32) -> Dir {
    let angle_deg = angle * (180.0 / PI);
    let mut angle = angle_deg + 90.0;
    if angle <= -22.5 {
        angle += 180.0;
    }
    let q = ((angle + 22.5) / 45.0).floor() as usize % 4;
    ANCHORS[q]
}

/// Returns the best anchor direction for a transfer context.
/// Each context entry is (position, segment index, segments).
pub fn get_best_anchor_tr(
    station_id: &StationId,
    lines: &IndexMap<LineId, LineV2>,
    transfers: &[LineId],
) -> Dir {
    let mut punishment = [0u32; 8];
    punishment[1] = 1;
    punishment[3] = 1;
    punishment[5] = 1;
    punishment[7] = 1;

    for line_id in transfers {
        let line = lines.get(line_id).unwrap();
        let sta = line.get_station(station_id).unwrap();
        let pos = sta.pos;
        let seg_idx = sta.segment;
        let segments = &line.segments;

        let seg = &segments[seg_idx];

        // Collect ray targets
        let mut targets = Vec::new();
        if pos != seg.start {
            targets.push(seg.start);
        } else if seg_idx > 0 {
            // consider previous segment
            targets.push(segments[seg_idx - 1].start);
        }
        if pos != seg.end {
            targets.push(seg.end);
        } else if seg_idx + 1 < segments.len() {
            // consider next segment
            targets.push(segments[seg_idx + 1].end);
        }

        for target in targets {
            let mut angle = (target - pos).angle() * (180.0 / PI);
            if angle <= -22.5 {
                angle += 360.0;
            }
            let di = ((angle + 22.5) / 45.0).floor() as usize % 8;
            let di1 = (di + 1) % 8; // next
            let di2 = (di + 7) % 8; // prev
            punishment[di] += 16;
            match di {
                0 | 2 | 4 | 6 => {
                    // right, left, up, down
                    punishment[di1] += 1;
                    punishment[di2] += 1;
                }
                1 | 5 => {
                    punishment[di1] += 8;
                    punishment[di2] += 4;
                }
                3 | 7 => {
                    punishment[di1] += 4;
                    punishment[di2] += 8;
                }
                _ => unreachable!(),
            }
        }
    }
    let min_idx = punishment.iter().position_min().unwrap_or(0);
    ANCHORS[min_idx]
}

// Example usage and test
#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_get_best_anchor() {
        assert_eq!(get_best_anchor(0.0), Dir::W);
        assert_eq!(get_best_anchor(45.0), Dir::S);
        assert_eq!(get_best_anchor(90.0), Dir::E);
        assert_eq!(get_best_anchor(135.0), Dir::N);
    }
}

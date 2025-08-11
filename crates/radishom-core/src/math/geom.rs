use crate::math::Vec2;

pub fn intersect_line_segments(a1: Vec2, a2: Vec2, b1: Vec2, b2: Vec2) -> Option<Vec2> {
    // Represent segments as: a1 + t*(a2-a1), b1 + u*(b2-b1), t,u in [0,1]
    let da = a2 - a1;
    let db = b2 - b1;
    let dp = a1 - b1;
    let denom = da.cross(db);

    if denom.abs() < f32::EPSILON {
        // Segments are parallel
        return None;
    }

    let t = db.cross(dp) / denom;
    let u = da.cross(dp) / denom;

    // Both t and u must be in [0, 1] for intersection within both segments
    if !(0.0..=1.0).contains(&t) || !(0.0..=1.0).contains(&u) {
        return None;
    }

    Some(Vec2 {
        x: a1.x + da.x * t,
        y: a1.y + da.y * t,
    })
}

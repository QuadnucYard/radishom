use itertools::Itertools;
use radishom_core::math::Vec2;
use serde::{Serialize, Serializer, ser::SerializeSeq};

pub struct Curve(pub Vec<CurveComponent>);

pub enum CurveComponent {
    Simple(Vec2),
    Move(Vec2),
    Line(Vec2),
    Quad(Vec2, Vec2),
    Cubic(Vec2, Vec2, Vec2),
}

impl Curve {
    pub fn rounded(points: &[(Vec2, Option<f32>)]) -> Self {
        let mut curve_points = vec![];
        for (i, &pt) in points.iter().enumerate() {
            if let (pt, Some(radius)) = pt {
                let p1 = points[i - 1].0;
                let p2 = points[i + 1].0;

                let t = round_corner(pt, p1, p2, radius);
                curve_points.push(t.0);
                curve_points.push(t.1);
            } else if i == 0 {
                curve_points.push(CurveComponent::Move(pt.0));
            } else {
                curve_points.push(CurveComponent::Line(pt.0));
            }
        }
        Self(curve_points)
    }

    pub fn rounded_polygon(vertices: Vec<Vec2>, radius: f32) -> Self {
        if radius <= 0.0 {
            return Self(vertices.into_iter().map(CurveComponent::Simple).collect());
        }

        let mut points = vec![];

        points.push(CurveComponent::Move(vertices[0]));
        for (p1, pt, p2) in vertices.into_iter().circular_tuple_windows() {
            let t = round_corner(pt, p1, p2, radius);
            points.push(t.0);
            points.push(t.1);
        }
        Self(points)
    }
}

fn round_corner(pt: Vec2, p1: Vec2, p2: Vec2, radius: f32) -> (CurveComponent, CurveComponent) {
    let d1 = (p1 - pt).length();
    let d2 = (p2 - pt).length();
    let radius = radius.min(d1 * 0.5).min(d2 * 0.5);
    let arc_p1 = pt + (p1 - pt) * radius / d1;
    let arc_p2 = pt + (p2 - pt) * radius / d2;
    let ct1 = (pt + arc_p1) * 0.5;
    let ct2 = (pt + arc_p2) * 0.5;
    (
        CurveComponent::Line(arc_p1),
        CurveComponent::Cubic(ct1, ct2, arc_p2),
    )
}

impl Serialize for CurveComponent {
    fn serialize<S>(&self, serializer: S) -> Result<S::Ok, S::Error>
    where
        S: Serializer,
    {
        match self {
            CurveComponent::Simple(v) => (0, v).serialize(serializer),
            CurveComponent::Move(v) => (1, v).serialize(serializer),
            CurveComponent::Line(v) => (2, v).serialize(serializer),
            CurveComponent::Quad(v1, v2) => (3, v1, v2).serialize(serializer),
            CurveComponent::Cubic(v1, v2, v3) => (4, v1, v2, v3).serialize(serializer),
        }
    }
}

impl Serialize for Curve {
    fn serialize<S>(&self, serializer: S) -> Result<S::Ok, S::Error>
    where
        S: Serializer,
    {
        let mut seq = serializer.serialize_seq(Some(self.0.len()))?;
        for comp in &self.0 {
            seq.serialize_element(comp)?;
        }
        seq.end()
    }
}

#[cfg(test)]
mod tests {
    use serde_json;

    use super::*;

    #[test]
    fn test_serialize_curv_ecomponent_simple() {
        let comp = CurveComponent::Simple(Vec2::new(1.0, 2.0));
        let json = serde_json::to_string(&comp).unwrap();
        assert_eq!(json, "[0,[1.0,2.0]]");
    }

    #[test]
    fn test_serialize_curve_component_move() {
        let comp = CurveComponent::Move(Vec2::new(3.0, 4.0));
        let json = serde_json::to_string(&comp).unwrap();
        assert_eq!(json, "[1,[3.0,4.0]]");
    }

    #[test]
    fn test_serialize_curve_component_line() {
        let comp = CurveComponent::Line(Vec2::new(5.0, 6.0));
        let json = serde_json::to_string(&comp).unwrap();
        assert_eq!(json, "[2,[5.0,6.0]]");
    }

    #[test]
    fn test_serialize_curve_component_quad() {
        let comp = CurveComponent::Quad(Vec2::new(1.0, 2.0), Vec2::new(3.0, 4.0));
        let json = serde_json::to_string(&comp).unwrap();
        assert_eq!(json, "[3,[1.0,2.0],[3.0,4.0]]");
    }

    #[test]
    fn test_serialize_curve_component_cubic() {
        let comp = CurveComponent::Cubic(
            Vec2::new(1.0, 2.0),
            Vec2::new(3.0, 4.0),
            Vec2::new(5.0, 6.0),
        );
        let json = serde_json::to_string(&comp).unwrap();
        assert_eq!(json, "[4,[1.0,2.0],[3.0,4.0],[5.0,6.0]]");
    }

    #[test]
    fn test_serialize_curve() {
        let curve = Curve(vec![
            CurveComponent::Move(Vec2::new(0.0, 0.0)),
            CurveComponent::Line(Vec2::new(1.0, 1.0)),
            CurveComponent::Quad(Vec2::new(2.0, 2.0), Vec2::new(3.0, 3.0)),
        ]);
        let json = serde_json::to_string(&curve).unwrap();
        assert_eq!(
            json,
            "[[1,[0.0,0.0]],[2,[1.0,1.0]],[3,[2.0,2.0],[3.0,3.0]]]"
        );
    }
}

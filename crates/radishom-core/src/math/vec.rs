use std::{fmt, ops};

use serde::{
    Deserialize, Deserializer, Serialize, Serializer,
    de::{self, SeqAccess, Visitor},
};

use crate::math::FloatExt;

#[derive(Debug, Default, Clone, Copy, PartialEq)]
pub struct Vec2 {
    pub x: f32,
    pub y: f32,
}

impl Vec2 {
    pub fn new(x: f32, y: f32) -> Self {
        Self { x, y }
    }

    pub fn angle(self) -> f32 {
        self.y.atan2(self.x)
    }

    pub fn length(self) -> f32 {
        (self.x * self.x + self.y * self.y).sqrt()
    }

    pub fn distance_to(self, other: Self) -> f32 {
        (other - self).length()
    }

    pub fn dot(self, other: Self) -> f32 {
        self.x * other.x + self.y * other.y
    }

    pub fn cross(self, other: Self) -> f32 {
        self.x * other.y - self.y * other.x
    }

    pub fn lerp(self, to: Self, t: f32) -> Self {
        Self::new(self.x + (to.x - self.x) * t, self.y + (to.y - self.y) * t)
    }

    /// Interpolate x for a given y along the line from `self` to `end`
    pub fn interpolate_x_for_y(self, end: Self, y: f32) -> f32 {
        self.x.lerp(end.x, (y - self.y) / (end.y - self.y))
    }

    /// Interpolate y for a given x along the line from `self` to `end`
    pub fn interpolate_y_for_x(self, end: Self, x: f32) -> f32 {
        self.y.lerp(end.y, (x - self.x) / (end.x - self.x))
    }
}

impl ops::Add for Vec2 {
    type Output = Self;

    fn add(self, other: Self) -> Self::Output {
        Vec2 {
            x: self.x + other.x,
            y: self.y + other.y,
        }
    }
}

impl ops::Sub for Vec2 {
    type Output = Self;

    fn sub(self, other: Self) -> Self::Output {
        Vec2 {
            x: self.x - other.x,
            y: self.y - other.y,
        }
    }
}

impl ops::Mul<f32> for Vec2 {
    type Output = Self;

    fn mul(self, scalar: f32) -> Self::Output {
        Vec2 {
            x: self.x * scalar,
            y: self.y * scalar,
        }
    }
}

impl ops::Div<f32> for Vec2 {
    type Output = Self;

    fn div(self, scalar: f32) -> Self::Output {
        Vec2 {
            x: self.x / scalar,
            y: self.y / scalar,
        }
    }
}

impl Serialize for Vec2 {
    fn serialize<S>(&self, serializer: S) -> Result<S::Ok, S::Error>
    where
        S: Serializer,
    {
        // Serialize as a tuple (x, y)
        (self.x, self.y).serialize(serializer)
    }
}

impl<'de> Deserialize<'de> for Vec2 {
    fn deserialize<D>(deserializer: D) -> Result<Self, D::Error>
    where
        D: Deserializer<'de>,
    {
        struct Vec2Visitor;

        impl<'de> Visitor<'de> for Vec2Visitor {
            type Value = Vec2;

            fn expecting(&self, formatter: &mut fmt::Formatter) -> fmt::Result {
                formatter.write_str("a tuple of two floats")
            }

            fn visit_seq<A>(self, mut seq: A) -> Result<Vec2, A::Error>
            where
                A: SeqAccess<'de>,
            {
                let x = seq
                    .next_element()?
                    .ok_or_else(|| de::Error::invalid_length(0, &self))?;
                let y = seq
                    .next_element()?
                    .ok_or_else(|| de::Error::invalid_length(1, &self))?;
                Ok(Vec2 { x, y })
            }
        }

        deserializer.deserialize_tuple(2, Vec2Visitor)
    }
}

#[cfg(test)]
mod tests {
    use serde_json;

    use super::*;

    #[test]
    fn test_vec2_lerp() {
        let a = Vec2::new(0.0, 0.0);
        let b = Vec2::new(10.0, 10.0);
        let result = a.lerp(b, 0.5);
        assert_eq!(result, Vec2::new(5.0, 5.0));
    }

    #[test]
    fn test_vec2_serialize_json() {
        let v = Vec2::new(1.5, -2.5);
        let json = serde_json::to_string(&v).unwrap();
        assert_eq!(json, "[1.5,-2.5]");
    }

    #[test]
    fn test_vec2_deserialize_json() {
        let json = "[1.1,2.2]";
        let v: Vec2 = serde_json::from_str(json).unwrap();
        assert_eq!(v, Vec2::new(1.1, 2.2));
    }

    #[test]
    fn test_vec2_serialize_deserialize_roundtrip() {
        let v = Vec2::new(42.0, -7.0);
        let json = serde_json::to_string(&v).unwrap();
        let v2: Vec2 = serde_json::from_str(&json).unwrap();
        assert_eq!(v, v2);
    }
}

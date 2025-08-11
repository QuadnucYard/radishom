pub mod geom;
mod vec;

pub use vec::Vec2;

pub trait FloatExt {
    fn lerp(self, to: Self, t: Self) -> Self;
}

impl FloatExt for f32 {
    fn lerp(self, to: Self, t: Self) -> Self {
        self + (to - self) * t
    }
}

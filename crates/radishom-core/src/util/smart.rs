use std::borrow::Cow;

use serde::de::{self, Deserialize, Deserializer};
use serde_derive::Deserialize;

/// A value that can be automatically determined.
///
/// Adapted from: https://github.com/typst/typst/blob/main/crates/typst-library/src/foundations/auto.rs
#[derive(Debug, Copy, Clone, Eq, PartialEq, Ord, PartialOrd, Hash)]
pub enum Smart<T> {
    /// The value should be determined smartly based on the circumstances.
    Auto,
    /// A specific value.
    Custom(T),
}

impl<T> Smart<T> {
    /// Whether the value is `Auto`.
    pub fn is_auto(&self) -> bool {
        matches!(self, Self::Auto)
    }

    /// Whether this holds a custom value.
    pub fn is_custom(&self) -> bool {
        matches!(self, Self::Custom(_))
    }

    /// Whether this is a `Smart::Custom(x)` and `f(x)` is true.
    pub fn is_custom_and<F>(self, f: F) -> bool
    where
        F: Fn(T) -> bool,
    {
        match self {
            Self::Auto => false,
            Self::Custom(x) => f(x),
        }
    }

    /// Returns a `Smart<&T>` borrowing the inner `T`.
    pub fn as_ref(&self) -> Smart<&T> {
        match self {
            Smart::Auto => Smart::Auto,
            Smart::Custom(v) => Smart::Custom(v),
        }
    }

    /// Returns the contained custom value.
    ///
    /// If the value is [`Smart::Auto`], returns `None`.
    ///
    /// Equivalently, this just converts `Smart` to `Option`.
    pub fn custom(self) -> Option<T> {
        match self {
            Self::Auto => None,
            Self::Custom(x) => Some(x),
        }
    }

    /// Map the contained custom value with `f`.
    pub fn map<F, U>(self, f: F) -> Smart<U>
    where
        F: FnOnce(T) -> U,
    {
        match self {
            Self::Auto => Smart::Auto,
            Self::Custom(x) => Smart::Custom(f(x)),
        }
    }

    /// Map the contained custom value with `f` if it contains a custom value,
    /// otherwise returns `default`.
    pub fn map_or<F, U>(self, default: U, f: F) -> U
    where
        F: FnOnce(T) -> U,
    {
        match self {
            Self::Auto => default,
            Self::Custom(x) => f(x),
        }
    }

    /// Keeps `self` if it contains a custom value, otherwise returns `other`.
    pub fn or(self, other: Smart<T>) -> Self {
        match self {
            Self::Custom(x) => Self::Custom(x),
            Self::Auto => other,
        }
    }

    /// Keeps `self` if it contains a custom value, otherwise returns the
    /// output of the given function.
    pub fn or_else<F>(self, f: F) -> Self
    where
        F: FnOnce() -> Self,
    {
        match self {
            Self::Custom(x) => Self::Custom(x),
            Self::Auto => f(),
        }
    }

    /// Returns `Auto` if `self` is `Auto`, otherwise calls the provided
    /// function on the contained value and returns the result.
    pub fn and_then<F, U>(self, f: F) -> Smart<U>
    where
        F: FnOnce(T) -> Smart<U>,
    {
        match self {
            Smart::Auto => Smart::Auto,
            Smart::Custom(x) => f(x),
        }
    }

    /// Returns the contained custom value or a provided default value.
    pub fn unwrap_or(self, default: T) -> T {
        match self {
            Self::Auto => default,
            Self::Custom(x) => x,
        }
    }

    /// Returns the contained custom value or computes a default value.
    pub fn unwrap_or_else<F>(self, f: F) -> T
    where
        F: FnOnce() -> T,
    {
        match self {
            Self::Auto => f(),
            Self::Custom(x) => x,
        }
    }

    /// Returns the contained custom value or the default value.
    pub fn unwrap_or_default(self) -> T
    where
        T: Default,
    {
        // we want to do this; the Clippy lint is not type-aware
        #[allow(clippy::unwrap_or_default)]
        self.unwrap_or_else(T::default)
    }
}

impl<T> Smart<Smart<T>> {
    /// Removes a single level of nesting, returns `Auto` if the inner or outer value is `Auto`.
    pub fn flatten(self) -> Smart<T> {
        match self {
            Smart::Custom(Smart::Auto) | Smart::Auto => Smart::Auto,
            Smart::Custom(Smart::Custom(v)) => Smart::Custom(v),
        }
    }
}

impl<T> Default for Smart<T> {
    fn default() -> Self {
        Self::Auto
    }
}

impl<T> serde::Serialize for Smart<T>
where
    T: serde::Serialize,
{
    fn serialize<S>(&self, serializer: S) -> Result<S::Ok, S::Error>
    where
        S: serde::Serializer,
    {
        match self {
            Smart::Auto => serializer.serialize_str("auto"),
            Smart::Custom(v) => v.serialize(serializer),
        }
    }
}

// Helper that matches exactly the string "auto"
struct AutoLiteral;

impl<'de> Deserialize<'de> for AutoLiteral {
    fn deserialize<D>(deserializer: D) -> Result<Self, D::Error>
    where
        D: Deserializer<'de>,
    {
        // Try to deserialize a string - if it's exactly "auto" accept,
        // otherwise return an error so the untagged enum will try the next variant.
        let s: Cow<'de, str> = Deserialize::deserialize(deserializer)?;
        if s == "auto" {
            Ok(AutoLiteral)
        } else {
            Err(de::Error::custom("not auto"))
        }
    }
}

// Untagged helper enum — order matters: Auto is tried first.
#[derive(Deserialize)]
#[serde(untagged)]
enum SmartHelper<T> {
    Auto(AutoLiteral),
    Custom(T),
}

// impl<'de, T> Deserialize<'de> for Smart<T>
// where
//     T: Deserialize<'de>,
// {
//     fn deserialize<D>(deserializer: D) -> Result<Self, D::Error>
//     where
//         D: Deserializer<'de>,
//     {
//         match SmartHelper::<T>::deserialize(deserializer)? {
//             SmartHelper::Auto(_) => Ok(Smart::Auto),
//             SmartHelper::Custom(t) => Ok(Smart::Custom(t)),
//         }
//     }
// }

use serde::de::{IntoDeserializer, MapAccess, SeqAccess, Visitor};
use std::{fmt, marker::PhantomData};
impl<'de, T> Deserialize<'de> for Smart<T>
where
    T: Deserialize<'de>,
{
    fn deserialize<D>(deserializer: D) -> Result<Smart<T>, D::Error>
    where
        D: Deserializer<'de>,
    {
        struct V<T>(PhantomData<T>);

        impl<'de, T> Visitor<'de> for V<T>
        where
            T: Deserialize<'de>,
        {
            type Value = Smart<T>;

            fn expecting(&self, f: &mut fmt::Formatter) -> fmt::Result {
                write!(f, "the string \"auto\" or any value that deserializes to T")
            }

            // strings
            fn visit_str<E>(self, v: &str) -> Result<Self::Value, E>
            where
                E: de::Error,
            {
                if v == "auto" {
                    Ok(Smart::Auto)
                } else {
                    T::deserialize(IntoDeserializer::<E>::into_deserializer(v))
                        .map(Smart::Custom)
                        .map_err(E::custom)
                }
            }

            fn visit_string<E>(self, v: String) -> Result<Self::Value, E>
            where
                E: de::Error,
            {
                if v == "auto" {
                    Ok(Smart::Auto)
                } else {
                    T::deserialize(IntoDeserializer::<E>::into_deserializer(v))
                        .map(Smart::Custom)
                        .map_err(E::custom)
                }
            }

            // primitives
            fn visit_bool<E>(self, b: bool) -> Result<Self::Value, E>
            where
                E: de::Error,
            {
                T::deserialize(IntoDeserializer::<E>::into_deserializer(b))
                    .map(Smart::Custom)
                    .map_err(E::custom)
            }

            fn visit_i64<E>(self, i: i64) -> Result<Self::Value, E>
            where
                E: de::Error,
            {
                T::deserialize(IntoDeserializer::<E>::into_deserializer(i))
                    .map(Smart::Custom)
                    .map_err(E::custom)
            }

            fn visit_u64<E>(self, u: u64) -> Result<Self::Value, E>
            where
                E: de::Error,
            {
                T::deserialize(IntoDeserializer::<E>::into_deserializer(u))
                    .map(Smart::Custom)
                    .map_err(E::custom)
            }

            fn visit_f64<E>(self, f: f64) -> Result<Self::Value, E>
            where
                E: de::Error,
            {
                T::deserialize(IntoDeserializer::<E>::into_deserializer(f))
                    .map(Smart::Custom)
                    .map_err(E::custom)
            }

            // sequences (arrays)
            fn visit_seq<A>(self, seq: A) -> Result<Self::Value, A::Error>
            where
                A: SeqAccess<'de>,
            {
                let de = de::value::SeqAccessDeserializer::new(seq);
                T::deserialize(de)
                    .map(Smart::Custom)
                    .map_err(<A::Error as de::Error>::custom)
            }

            // maps / objects
            fn visit_map<A>(self, map: A) -> Result<Self::Value, A::Error>
            where
                A: MapAccess<'de>,
            {
                let de = de::value::MapAccessDeserializer::new(map);
                T::deserialize(de)
                    .map(Smart::Custom)
                    .map_err(<A::Error as de::Error>::custom)
            }

            // unit / null
            fn visit_unit<E>(self) -> Result<Self::Value, E>
            where
                E: de::Error,
            {
                // forward unit to T::deserialize (useful when T = Option<_>)
                T::deserialize(de::value::UnitDeserializer::<E>::new())
                    .map(Smart::Custom)
                    .map_err(E::custom)
            }

            fn visit_none<E>(self) -> Result<Self::Value, E>
            where
                E: de::Error,
            {
                // JSON `null` -> treat like unit; Option<T> will decode to None.
                self.visit_unit()
            }

            // Some(inner) — forward inner deserializer directly to T
            fn visit_some<D2>(self, deserializer: D2) -> Result<Self::Value, D2::Error>
            where
                D2: Deserializer<'de>,
            {
                T::deserialize(deserializer).map(Smart::Custom)
            }
        }

        deserializer.deserialize_any(V(PhantomData))
    }
}
/* impl<'de, T> Deserialize<'de> for Smart<T>
where
    T: Deserialize<'de>,
{
    fn deserialize<D>(deserializer: D) -> Result<Self, D::Error>
    where
        D: Deserializer<'de>,
    {
        // Deserialize into a string without full value parsing
        let cow: Result<Cow<'de, str>, _> = Deserialize::deserialize(
            &mut serde::de::value::BorrowedStrDeserializer::new(deserializer),
        );
        if let Ok(s) = cow {
            if s == "auto" {
                return Ok(Smart::Auto);
            }
            // Fall through to parse as T
        }

        // Parse as T
        T::deserialize(deserializer).map(Smart::Custom)
    }
} */
#[cfg(test)]
mod tests {
    use ciborium::cbor;

    use super::*;

    fn roundtrip<T>(value: T, expected_json: &str)
    where
        T: std::fmt::Debug + PartialEq + serde::Serialize + for<'a> serde::Deserialize<'a>,
    {
        let json = serde_json::to_string(&value).unwrap();
        assert_eq!(json, expected_json);
        assert_eq!(serde_json::from_str::<T>(&json).unwrap(), value);
    }

    // fn roundtrip_cbor<T>(value: T, expected: &ciborium::Value)
    // where
    //     T: std::fmt::Debug + PartialEq + serde::Serialize + for<'a> serde::Deserialize<'a>,
    // {
    //     let mut buf = Vec::new();
    //     ciborium::into_writer(&value, &mut buf).unwrap();
    //     let json = serde_json::to_string(&value).unwrap();
    //     assert_eq!(json, expected_json);
    //     assert_eq!(serde_json::from_str::<T>(&json).unwrap(), value);
    // }

    #[test]
    fn test_auto() {
        let smart: Smart<i32> = Smart::Auto;
        roundtrip(smart, "\"auto\"");
    }

    #[test]
    fn test_custom_int() {
        let smart = Smart::Custom(42);
        roundtrip(smart, "42");
    }

    #[test]
    fn test_custom_bool() {
        let smart = Smart::Custom(true);
        roundtrip(smart, "true");
    }

    #[test]
    fn test_custom_float() {
        let smart = Smart::Custom(1.14);
        roundtrip(smart, "1.14");
    }

    #[test]
    fn test_custom_vec() {
        let smart = Smart::Custom(vec![1, 2, 3]);
        roundtrip(smart, "[1,2,3]");
    }

    #[test]
    fn test_custom_map() {
        let mut map = std::collections::BTreeMap::new();
        map.insert("a".to_string(), 1);
        map.insert("b".to_string(), 2);
        let smart = Smart::Custom(map.clone());
        roundtrip(smart, "{\"a\":1,\"b\":2}");
    }

    #[test]
    fn test_custom_enum() {
        #[derive(Debug, PartialEq, Eq, serde_derive::Deserialize, serde_derive::Serialize)]
        enum MyEnum {
            A,
            B,
            C,
        }

        let smart = Smart::Custom(MyEnum::B);
        roundtrip(smart, "\"B\"");
    }

    // #[test]
    // fn test_custom_option_some_int() {
    //     let smart = Smart::Custom(Some(1));
    //     roundtrip(smart, "1");
    // }

    // #[test]
    // fn test_custom_option_some_str() {
    //     let smart = Smart::Custom(Some("1".to_string()));
    //     roundtrip(smart, "\"1\"");
    // }

    // #[test]
    // fn test_custom_option_none() {
    //     let smart = Smart::Custom(Option::<i32>::None);
    //     roundtrip(smart, "null");
    // }

    // #[test]
    // fn test_cbor() {
    //     let value = cbor!("none").unwrap();
    //     let smart: Smart<Option<String>> = value.deserialized().unwrap();
    //     assert_eq!(smart, Smart::Custom(Some("none".to_string())));
    // }

    #[test]
    fn test_cbor00() {
        let value = cbor!("auto").unwrap();
        let _smart: AutoLiteral = value.deserialized().unwrap();
    }

    #[test]
    fn test_cbor0() {
        let value = cbor!("auto").unwrap();
        let smart: Smart<String> = value.deserialized().unwrap();
        assert_eq!(smart, Smart::Auto);
    }

    // #[test]
    // fn test_cbor2() {
    //     let value = cbor!("auto").unwrap();
    //     let smart: Smart<Option<String>> = value.deserialized().unwrap();
    //     assert_eq!(smart, Smart::Auto);
    // }

    // #[test]
    // fn test_cbor3() {
    //     let value = cbor!(null).unwrap();
    //     let smart: Smart<Option<String>> = value.deserialized().unwrap();
    //     assert_eq!(smart, Smart::Custom(None));
    // }
}

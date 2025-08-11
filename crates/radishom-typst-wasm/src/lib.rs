use radishom_core::model::radish::RadishV0;
use typst_wasm_protocol::wasm_export;

#[wasm_export]
pub fn construct_radish(data: &[u8]) -> Result<Vec<u8>, String> {
    let value: ciborium::Value = ciborium::from_reader(data).unwrap();
    let j = serde_json::to_string(&value).unwrap();
    let jd = &mut serde_json::Deserializer::from_str(&j);
    let result: RadishV0 =
        serde_path_to_error::deserialize(jd).map_err(|e| format!("Failed to deserialize: {e}"))?;
    let input = result;
    let output = input.resolve();
    let mut buf = Vec::new();
    ciborium::into_writer(&output, &mut buf).map_err(|e| format!("Failed to serialize: {e}"))?;
    Ok(buf)
}

// use wasm_minimal_protocol::*;

// initiate_protocol!();

// #[wasm_func]
// pub fn hello(name: &[u8]) -> Vec<u8> {
//     format!("Hello, {}!", String::from_utf8_lossy(name)).into_bytes()
// }

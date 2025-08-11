use radishom_core::model::radish::RadishV0;
use typst_wasm_protocol::wasm_export;

#[wasm_export]
pub fn construct_radish(data: &[u8]) -> Result<Vec<u8>, String> {
    let input: RadishV0 =
        ciborium::from_reader(data).map_err(|e| format!("Failed to deserialize: {e}"))?;
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

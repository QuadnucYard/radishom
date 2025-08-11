use radishom_core::model::{line::LineV0, metro::MetroV1};
use typst_wasm_protocol::wasm_export;

#[wasm_export]
pub fn construct_line(data: &[u8]) -> Result<Vec<u8>, String> {
    let input_line: LineV0 =
        ciborium::from_reader(data).map_err(|e| format!("Failed to deserialize: {e}"))?;
    let output_line = input_line.resolve();
    let mut buf = Vec::new();
    ciborium::into_writer(&output_line, &mut buf)
        .map_err(|e| format!("Failed to serialize: {e}"))?;
    Ok(buf)
}

#[wasm_export]
pub fn construct_metro(data: &[u8]) -> Result<Vec<u8>, String> {
    let input_metro: MetroV1 =
        ciborium::from_reader(data).map_err(|e| format!("Failed to deserialize: {e}"))?;
    let output_metro = input_metro.resolve();
    let mut buf = Vec::new();
    ciborium::into_writer(&output_metro, &mut buf)
        .map_err(|e| format!("Failed to serialize: {e}"))?;
    Ok(buf)
}

// use wasm_minimal_protocol::*;

// initiate_protocol!();

// #[wasm_func]
// pub fn hello(name: &[u8]) -> Vec<u8> {
//     format!("Hello, {}!", String::from_utf8_lossy(name)).into_bytes()
// }

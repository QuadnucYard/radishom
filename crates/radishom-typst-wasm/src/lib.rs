use radishom_core::model::radish::RadishV0;
use typst_wasm_protocol::wasm_export;

#[wasm_export]
pub fn construct_radish(data: &[u8]) -> Result<Vec<u8>, String> {
    // let value: ciborium::Value = ciborium::from_reader(data).unwrap();
    // return encode(&format!("{value:#?}"));
    // let j = serde_json::to_string(&value).unwrap();
    // let jd = &mut serde_json::Deserializer::from_str(&j);
    // let result: RadishV0 =
    //     serde_path_to_error::deserialize(jd).map_err(|e| format!("Failed to deserialize: {e}"))?;
    let mut buf = vec![0u8; 256 * 1024];
    let input: RadishV0 = ciborium::from_reader_with_buffer(data, &mut buf)
        .map_err(|e| format!("Failed to deserialize: {e}"))?;
    let output = input.resolve();
    encode(&output)
}

#[wasm_export]
pub fn construct_radish_de(data: &[u8]) -> Result<Vec<u8>, String> {
    let mut buf = vec![0u8; 256 * 1024];
    let input: RadishV0 = ciborium::from_reader_with_buffer(data, &mut buf)
        .map_err(|e| format!("Failed to deserialize: {e}"))?;
    let output = input.resolve();
    encode(&output)
}

#[wasm_export]
pub fn construct_radish_json(data: &[u8]) -> Result<Vec<u8>, String> {
    let jd = &mut serde_json::Deserializer::from_slice(data);
    let input: RadishV0 =
        serde_path_to_error::deserialize(jd).map_err(|e| format!("Failed to deserialize: {e}"))?;
    let output = input.resolve();
    serde_json::to_vec(&output).map_err(|e| format!("Failed to deserialize: {e}"))
}

fn encode<T>(value: &T) -> Result<Vec<u8>, String>
where
    T: serde::Serialize,
{
    let mut buf = Vec::new();
    ciborium::into_writer(value, &mut buf).map_err(|e| format!("Failed to serialize: {e}"))?;
    Ok(buf)
}

use std::{fs::read, time::Instant};

use radishom_core::model::radish::RadishV0;

fn main() {
    let data = read("nj.json").unwrap();
    let j: serde_json::Value = serde_json::from_slice(&data).unwrap();

    let mut buf = Vec::new();
    ciborium::into_writer(&j, &mut buf).unwrap();

    let mut buf2 = vec![0u8; 256 * 1024];
    let t0 = Instant::now();
    let input: RadishV0 =
        ciborium::from_reader_with_buffer(buf.as_slice(), buf2.as_mut_slice()).unwrap();
    println!("{:?}", t0.elapsed());

    let t0 = Instant::now();
    let _output = input.resolve();
    println!("{:?}", t0.elapsed());
}

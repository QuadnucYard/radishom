use std::collections::BTreeMap;

use indexmap::IndexMap;

use crate::model::{
    line::{LineId, LineV1, LineV2},
    station::StationId,
};

pub type Transfers = BTreeMap<StationId, Vec<LineId>>;

pub fn resolve_transfers(lines: &[LineV1]) -> Transfers {
    let mut station_collection = Transfers::new();

    for line in lines {
        for station in line.stations.iter() {
            let entry = station_collection.entry(station.id.clone()).or_default();
            entry.push(line.id.clone());
        }
    }

    keep_(station_collection)
}

pub fn resolve_enabled_transfers(lines: &IndexMap<LineId, LineV2>) -> Transfers {
    let mut station_collection = Transfers::new();

    for line in lines.values() {
        if line.disabled {
            continue;
        }
        for station in line.stations.iter() {
            if !station.disabled && !station.no_transfer {
                let entry = station_collection.entry(station.id.clone()).or_default();
                entry.push(line.id.clone());
            }
        }
    }

    keep_(station_collection)
}

fn keep_(station_collection: Transfers) -> Transfers {
    station_collection
        .into_iter()
        .filter(|(_, lines)| lines.len() > 1)
        .collect()
}

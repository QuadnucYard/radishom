use std::collections::BTreeMap;

use indexmap::IndexMap;
use serde::{Deserialize, Serialize};

use crate::{
    layout::positioning::resolve_stations_final_pos,
    model::{
        line::{LineId, LineV1, LineV2},
        station::StationId,
    },
};

#[derive(Deserialize)]
#[serde(rename_all = "kebab-case")]
pub struct MetroV1 {
    pub lines: Vec<LineV1>,
}

#[derive(Serialize)]
#[serde(rename_all = "kebab-case")]
pub struct MetroV2 {
    pub lines: IndexMap<LineId, LineV2>,
    pub transfers: BTreeMap<StationId, Vec<LineId>>,
}

impl MetroV1 {
    pub fn resolve(self) -> MetroV2 {
        let transfers = resolve_transfers(&self.lines);
        let lines = resolve_stations_final_pos(self.lines, &transfers);
        MetroV2 { lines, transfers }
    }
}

fn resolve_transfers(lines: &[LineV1]) -> BTreeMap<StationId, Vec<LineId>> {
    let mut station_collection = BTreeMap::<StationId, Vec<LineId>>::new();

    for line in lines {
        for station in line.stations.iter() {
            let entry = station_collection.entry(station.id.clone()).or_default();
            entry.push(line.id.clone());
        }
    }

    station_collection
        .into_iter()
        .filter_map(|(station_id, lines)| {
            if lines.len() > 1 {
                Some((station_id, lines))
            } else {
                None
            }
        })
        .collect()
}

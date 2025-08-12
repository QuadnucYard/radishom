use indexmap::IndexMap;
use serde_derive::{Deserialize, Serialize};

use crate::{
    feature::{FeatureMap, FeatureVec},
    layout::positioning::resolve_stations_final_pos,
    model::line::{LineId, LineV0, LineV2},
    network::transfers::{Transfers, resolve_transfers},
};

#[derive(Deserialize)]
#[serde(rename_all = "kebab-case")]
pub struct MetroV0 {
    pub lines: Vec<LineV0>,

    pub features: FeatureMap,
    pub default_features: FeatureVec,
}

#[derive(Serialize)]
#[serde(rename_all = "kebab-case")]
pub struct MetroV1 {
    pub lines: IndexMap<LineId, LineV2>,
    pub transfers: Transfers,

    pub features: FeatureMap,
    pub default_features: FeatureVec,
}

impl MetroV0 {
    pub fn resolve(self) -> MetroV1 {
        let lines = self
            .lines
            .into_iter()
            .map(|line| line.resolve())
            .collect::<Vec<_>>();
        let transfers = resolve_transfers(&lines);
        let lines = resolve_stations_final_pos(lines, &transfers);
        MetroV1 {
            lines,
            transfers,

            features: self.features,
            default_features: self.default_features,
        }
    }
}

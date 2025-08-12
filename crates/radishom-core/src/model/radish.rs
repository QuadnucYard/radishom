use std::{borrow::Cow, collections::BTreeSet};

use indexmap::IndexMap;
use serde_derive::{Deserialize, Serialize};

use crate::{
    feature::{FeatureVec, merge_features, resolve_all_features, resolve_enabled_features},
    layout::anchor::{get_best_anchor, get_best_anchor_tr},
    model::{
        line::{LineId, LineV2},
        metro::{MetroV0, MetroV1},
    },
    network::transfers::{Transfers, resolve_enabled_transfers},
    util::Smart,
};

#[derive(Deserialize)]
#[serde(rename_all = "kebab-case")]
pub struct RadishV0<'a> {
    pub metro: MetroV0<'a>,

    /// Enabled features
    pub features: FeatureVec<'a>,
    /// Whether to include default features
    pub default_features: bool,
    /// Whether to include all features (unimplemented)
    pub all_features: bool,
    /// Whether to enable all elements
    pub enable_all: bool,

    pub consider_disabled: bool,
}

#[derive(Serialize)]
#[serde(rename_all = "kebab-case")]
pub struct RadishV1<'a> {
    pub metro: MetroV1<'a>,
    pub enabled_transfers: Transfers<'a>,

    /// Enabled features
    pub features: FeatureVec<'a>,
    /// Whether to include default features
    pub default_features: bool,
    /// Whether to include all features (unimplemented)
    pub all_features: bool,
    /// Whether to enable all elements
    pub enable_all: bool,

    pub consider_disabled: bool,
}

impl<'a> RadishV0<'a> {
    pub fn resolve(self) -> RadishV1<'a> {
        let mut metro = self.metro.resolve();

        let global_enabled_features = if self.all_features {
            resolve_all_features(&metro.features)
        } else if self.default_features {
            let features = merge_features(&self.features, &metro.default_features);
            resolve_enabled_features(&metro.features, &features)
        } else {
            resolve_enabled_features(&metro.features, &self.features)
        };
        let global_enabled_features = global_enabled_features.into_iter().collect::<Vec<_>>();

        // we should remove unavailable transfer stations here

        for line in metro.lines.values_mut() {
            let mut enabled_features = BTreeSet::new();
            enabled_features.extend(global_enabled_features.clone());
            enabled_features.extend(if self.default_features {
                let features = merge_features(&global_enabled_features, &line.default_features);
                resolve_enabled_features(&line.features, &features)
            } else {
                resolve_enabled_features(&line.features, &global_enabled_features)
            });

            let line_feat_id = Cow::Owned(format!("L:{}", line.id));

            line.disabled =
                !self.enable_all && line.optional && !enabled_features.contains(&line_feat_id);
            if !line.disabled && !enabled_features.contains(&line_feat_id) {
                enabled_features.insert(line_feat_id);
            }

            if !self.enable_all {
                for sec in line.sections.iter_mut() {
                    sec.disabled = sec.cfg.is_disabled_by(&enabled_features);
                }

                for seg in line.segments.iter_mut() {
                    seg.disabled = seg.cfg.is_disabled_by(&enabled_features);
                }

                for sta in line.stations.iter_mut() {
                    sta.disabled = sta.cfg.is_disabled_by(&enabled_features);
                }
            }

            // find terminuses
            line.mark_terminuses(self.consider_disabled);
        }

        resolve_pending_station_attrs(&mut metro.lines, &metro.transfers);

        RadishV1 {
            enabled_transfers: resolve_enabled_transfers(&metro.lines),
            metro,

            features: self.features.clone(),
            default_features: self.default_features,
            all_features: self.all_features,
            enable_all: self.enable_all,
            consider_disabled: self.consider_disabled,
        }
    }
}

fn resolve_pending_station_attrs<'a>(
    lines: &mut IndexMap<LineId<'a>, LineV2<'a>>,
    transfers: &Transfers<'a>,
) {
    let mut pending = Vec::new();
    for line in lines.values() {
        for (j, station) in line.stations.iter().enumerate() {
            if station.anchor.is_custom() {
                continue;
            }
            let anchor = if station.no_transfer || !transfers.contains_key(&station.id) {
                get_best_anchor(line.segments[station.segment].angle)
            } else {
                get_best_anchor_tr(&station.id, lines, transfers.get(&station.id).unwrap())
            };
            pending.push((line.id.clone(), j, anchor));
        }
    }
    for (line_id, j, anchor) in pending {
        lines.get_mut(&line_id).unwrap().stations[j].anchor = Smart::Custom(anchor);
    }
}

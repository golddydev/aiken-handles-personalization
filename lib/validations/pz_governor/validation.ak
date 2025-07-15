use aiken/transaction.{Transaction}
use common/assets.{AssetClass}
use configs/settings.{PzSettings, find_pz_settings}
use configs/settings_v1.{PzSettingsV1}
use validations/pz_governor/types.{PzIndexes}
use validations/pz_governor/utils.{find_pz_utxo}

// Validation:
//
// CAUTION: 
// This function assumes that `policy_ids` from `PzSettingsV1` are always valid ones.
//
pub fn can_personalize(
  transaction: Transaction,
  asset_class: AssetClass,
  pz_indexes: PzIndexes,
) -> Bool {
  let Transaction { inputs, reference_inputs, .. } = transaction

  // must attach `PzSettings` NFT in reference inputs.
  let PzSettings { data: settings_data, .. } =
    find_pz_settings(reference_inputs)
  expect settings_datum: PzSettingsV1 = settings_data
  let PzSettingsV1 { policy_ids, .. } = settings_datum

  // must have valid `pz_utxo`
  let (pz_utxo, old_datum) = find_pz_utxo(inputs, policy_ids, asset_class)

  todo
}

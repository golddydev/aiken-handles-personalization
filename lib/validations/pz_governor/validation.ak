use aiken/transaction.{Transaction}
use common/assets.{AssetClass}
use common/cip68.{CIP68Datum}
use common/utils.{check_transaction_is_valid_after_finite_time} as common_utils
use configs/settings.{PzSettings, find_pz_settings}
use configs/settings_v1.{PzSettingsV1}
use validations/pz_governor/personalize.{
  check_new_extra, check_new_metadata, parse_pz_indexes,
}
use validations/pz_governor/types.{PzIndexes}
use validations/pz_governor/utils.{
  check_ref_output, find_pz_utxo, parse_pz_asset_name,
}

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
  let Transaction {
    inputs,
    reference_inputs,
    outputs,
    validity_range,
    extra_signatories,
    ..
  } = transaction
  let (_policy_id, asset_name) = asset_class

  // transaction starts after valid time
  let transaction_start_time =
    check_transaction_is_valid_after_finite_time(validity_range)

  // must attach `PzSettings` NFT in reference inputs.
  let PzSettings { data: settings_data, .. } =
    find_pz_settings(reference_inputs)
  expect settings_datum: PzSettingsV1 = settings_data
  let PzSettingsV1 { policy_ids, .. } = settings_datum

  // must have valid `pz_utxo`
  let (pz_utxo, old_datum) = find_pz_utxo(inputs, policy_ids, asset_class)
  let CIP68Datum {
    metadata: old_metadata,
    version: old_version,
    extra: old_extra_data,
  } = old_datum

  // parse pz_indexes
  let (
    ref_output,
    user_output_opt,
    treasury_output_opt,
    provider_fee_output_opt,
    shared_fee_output_opt,
  ) = parse_pz_indexes(outputs, pz_indexes)

  // parse pz_asset_name
  let pz_handle = parse_pz_asset_name(asset_name)

  // `ref_output` must be valid
  let new_datum = check_ref_output(ref_output, pz_utxo)
  let CIP68Datum {
    metadata: new_metadata,
    version: new_version,
    extra: new_extra_data,
  } = new_datum

  // `new_version` must be >= 0
  let is_version_valid = new_version >= 0 && new_version >= old_version
  expect is_version_valid

  // `new_metadata` must be valid
  let (new_image, new_media_type) =
    check_new_metadata(old_metadata, new_metadata)

  // `new extra` must be valid
  let (old_last_edited_time_opt, new_extra) =
    check_new_extra(
      new_extra_data,
      old_extra_data,
      extra_signatories,
      transaction_start_time,
    )

  todo
}

use aiken/transaction.{Transaction}
use common/assets.{AssetClass}
use common/cip68.{CIP68Datum}
use common/utils.{check_transaction_is_valid_after_finite_time} as common_utils
use configs/settings.{PzSettings, find_pz_settings}
use configs/settings_v1.{PzSettingsV1}
use validations/pz_governor/personalize.{
  check_fees_are_paid, check_new_datum_reset, check_new_extra,
  check_new_metadata, parse_outputs,
}
use validations/pz_governor/types.{PzIndexes}
use validations/pz_governor/utils.{
  check_pz_output, find_pz_utxo, parse_pz_asset_name,
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
  let (policy_id, asset_name) = asset_class

  // transaction starts after valid time
  let transaction_start_time =
    check_transaction_is_valid_after_finite_time(validity_range)

  // must attach `PzSettings` NFT in reference inputs.
  let PzSettings { data: settings_data, .. } =
    find_pz_settings(reference_inputs)
  expect settings_v1: PzSettingsV1 = settings_data
  let PzSettingsV1 { policy_ids, settings_script_hash, .. } = settings_v1

  // must have valid `pz_utxo`
  let (pz_utxo, old_datum) = find_pz_utxo(inputs, policy_ids, asset_class)
  let CIP68Datum {
    metadata: old_metadata,
    version: old_version,
    extra: old_extra_data,
  } = old_datum
  expect old_extra: Pairs<Data, Data> = old_extra_data

  // parse pz_indexes
  let (
    pz_output,
    user_output,
    treasury_output_opt,
    provider_fee_output_opt,
    shared_fee_output_opt,
  ) = parse_outputs(outputs, pz_indexes)

  // parse pz_asset_name
  let (pz_handle, handle_name) = parse_pz_asset_name(asset_name)

  // `pz_output` must be valid
  let new_datum = check_pz_output(pz_output, pz_utxo)
  let CIP68Datum {
    metadata: new_metadata,
    version: new_version,
    extra: new_extra_data,
  } = new_datum
  expect new_extra: Pairs<Data, Data> = new_extra_data

  // `new_version` must be >= 0
  let is_version_valid = new_version >= 0 && new_version >= old_version
  expect is_version_valid

  // `new_metadata` must be valid
  let (new_image, new_media_type) =
    check_new_metadata(new_metadata, old_metadata)

  // `new extra` must be valid
  let old_last_edited_time_opt =
    check_new_extra(
      new_extra,
      old_extra,
      extra_signatories,
      transaction_start_time,
    )

  // check `is_new_datum_reset`
  let is_new_datum_reset = check_new_datum_reset(new_extra, new_image)

  // check designer settings are valid.
  // let designer_settings_valid = check_designer_settings(new_extra, old_extra)
  // check fees are paid
  // fees are for designer settings update.
  let fee_paid =
    check_fees_are_paid(
      pz_handle,
      settings_v1,
      treasury_output_opt,
      provider_fee_output_opt,
      shared_fee_output_opt,
      old_last_edited_time_opt,
      transaction_start_time,
    )

  // TODO:
  // check designer settings
  todo
}

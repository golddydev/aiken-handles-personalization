use aiken/transaction.{Transaction}
use common/assets.{AssetClass}
use common/cip68.{CIP68Datum}
use common/utils.{check_transaction_is_valid_after_finite_time} as common_utils
use configs/settings.{PzSettings, find_pz_settings}
use configs/settings_v1.{PzSettingsV1}
use handles/utils.{parse_handle_asset_name} as handle_utils
use subhandle/utils.{check_pz_enabled} as subhandle_utils
use validations/pz_governor/personalize.{
  check_fees_are_paid, check_new_extra, check_new_metadata, parse_outputs,
}
use validations/pz_governor/types.{PzIndexes}
use validations/pz_governor/utils.{
  check_pz_output, check_user_output, find_pz_utxo,
}

// Validation:
//
// CAUTION: 
// This function assumes that `policy_ids` from `PzSettingsV1` are always valid ones.
//
// NOTE:
// `asset_class` is Reference Handle or Virtual Subhandle Asset Class
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
  let (_, asset_name) = asset_class

  // transaction starts after valid time
  let transaction_start_time =
    check_transaction_is_valid_after_finite_time(validity_range)

  // must attach `PzSettings` NFT in reference inputs.
  let PzSettings { data: settings_data, .. } =
    find_pz_settings(reference_inputs)
  expect settings_v1: PzSettingsV1 = settings_data
  let PzSettingsV1 { policy_ids, .. } = settings_v1

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
  let (pz_handle, handle_name, is_subhandle) =
    parse_handle_asset_name(asset_name)

  // check `pz_output` is valid
  let new_datum = check_pz_output(pz_output, pz_utxo)
  let CIP68Datum {
    metadata: new_metadata,
    version: new_version,
    extra: new_extra_data,
  } = new_datum
  expect new_extra: Pairs<Data, Data> = new_extra_data

  // check `user_output` is valid
  let user_output_valid = check_user_output(user_output, pz_handle)
  expect user_output_valid

  // `new_version` must be >= 0
  let is_version_valid = new_version >= 0 && new_version >= old_version
  expect is_version_valid

  // `new_metadata` must be valid
  let new_metadata_valid = check_new_metadata(new_metadata, old_metadata)
  expect new_metadata_valid

  // `new extra` must be valid
  let old_last_edited_time_opt =
    check_new_extra(
      new_extra,
      old_extra,
      extra_signatories,
      transaction_start_time,
    )

  // check pz is enabled
  let (pz_enabled, payment_address_opt) =
    check_pz_enabled(pz_handle, policy_ids, reference_inputs)
  expect pz_enabled

  // check fees are paid
  // fees are for designer settings update.
  let fees_are_correctly_paid =
    check_fees_are_paid(
      handle_name,
      is_subhandle,
      settings_v1,
      payment_address_opt,
      treasury_output_opt,
      provider_fee_output_opt,
      shared_fee_output_opt,
      old_last_edited_time_opt,
      transaction_start_time,
    )
  expect fees_are_correctly_paid

  // TODO:
  // check designer settings
  True
}

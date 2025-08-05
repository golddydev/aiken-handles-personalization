use aiken/merkle_patricia_forestry as mpt
use aiken/transaction.{Transaction}
use common/assets.{AssetClass}
use common/cip68.{CIP68Datum}
use common/utils.{check_transaction_is_valid_after_finite_time} as common_utils
use configs/settings.{PzSettings, find_pz_settings}
use configs/settings_v1.{PzSettingsV1}
use pz_items/utils.{find_pz_items} as pz_items_utils
use validations/pz_governor/personalize.{
  check_bg_asset_constraints, check_new_datum_reset, check_new_extra,
  check_new_metadata, check_pz_assets, parse_pz_indexes,
}
use validations/pz_governor/types.{PzAssetsProofs, PzIndexes}
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
  pz_assets_proofs: PzAssetsProofs,
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
  expect settings_datum: PzSettingsV1 = settings_data
  let PzSettingsV1 { policy_ids, settings_script_hash, .. } = settings_datum

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
  let (pz_handle, handle_name) = parse_pz_asset_name(asset_name)

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

  // check `is_new_datum_reset`
  let is_new_datum_reset = check_new_datum_reset(new_extra, new_image)

  // there must be `PzItems` reference input. (input with `PzItems` assets)
  let pz_items = find_pz_items(reference_inputs, settings_script_hash)

  // build Policies MPT and Beta Assets MPT
  let policies_mpt = mpt.from_root(pz_items.policies)
  let beta_assets_mpt = mpt.from_root(pz_items.beta_assets)

  // check pz_assets PzFlags
  let (pz_flags, bg_datum_opt, bg_asset_id_opt, pfp_asset_id_opt) =
    check_pz_assets(
      new_extra,
      policies_mpt,
      beta_assets_mpt,
      pz_assets_proofs,
      user_output_opt,
      reference_inputs,
    )

  // check bg asset's contraints
  let bg_constraints_met =
    when bg_datum_opt is {
      None -> True
      Some(bg_datum) ->
        check_bg_asset_constraints(
          bg_datum,
          user_output_opt,
          reference_inputs,
          extra_signatories,
          pfp_asset_id_opt,
          policy_id,
          handle_name,
        )
    }
  expect bg_constraints_met

  todo
}

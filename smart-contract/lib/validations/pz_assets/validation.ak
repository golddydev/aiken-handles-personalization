use aiken/merkle_patricia_forestry as mpt
use aiken/transaction.{Transaction}
use common/cip68.{CIP68Datum}
use common/collections.{get_single_int_value_from_pairs}
use pz_items/utils.{find_pz_items} as pz_items_utils
use validations/pz_assets/types.{PzAssetsProofs}
use validations/pz_assets/utils.{
  check_pz_flags, check_pz_images_and_assets_match, get_pz_datum,
}

// This Function checks
// - `bg_asset` and `pfp_asset` must be user token or RFT
// - `bg_image` and `pfp_image` must be same as `bg_asset` and `pfp_asset` datum images (if they are CIP68)
// - `user_output` must have `bg_asset` and `pfp_asset` if they are set.
// - `bg_asset` and `pfp_asset` are approved by Policies MPT and Beta Assets MPT
// - `nsfw` and `trial` flags are correctly set from `bg_asset` and `pfp_asset` Flags.
//
// CAUTION: This function assumes that `pz_governor` withdrawal script is executed
// and first output must be `pz_output`.
//
pub fn check_pz_assets(
  pz_assets_proofs: PzAssetsProofs,
  transaction: Transaction,
) -> Bool {
  let Transaction { reference_inputs, outputs, .. } = transaction

  // parse outputs
  expect [pz_output, user_output, ..] = outputs

  // get pz_datum
  let new_datum = get_pz_datum(pz_output)
  let CIP68Datum { extra: new_extra, .. } = new_datum
  expect new_extra: Pairs<Data, Data> = new_extra

  // check `bg_image` and `pfp_image` match with `bg_asset` and `pfp_asset`
  let (bg_asset_id_opt, pfp_asset_id_opt) =
    check_pz_images_and_assets_match(new_extra, user_output, reference_inputs)

  // there must be `PzItems` reference input. (input with `PzItems` assets)
  let pz_items = find_pz_items(reference_inputs)

  // build Policies MPT and Beta Assets MPT
  let policies_mpt = mpt.from_root(pz_items.policies)
  let beta_assets_mpt = mpt.from_root(pz_items.beta_assets)

  // get pz_flags from new_extra
  let nsfw_opt = get_single_int_value_from_pairs(new_extra, "nsfw")
  expect Some(nsfw) = nsfw_opt
  let trial_opt = get_single_int_value_from_pairs(new_extra, "trial")
  expect Some(trial) = trial_opt

  // check pz_flags
  let pz_flags_valid =
    check_pz_flags(
      bg_asset_id_opt,
      pfp_asset_id_opt,
      nsfw,
      trial,
      policies_mpt,
      beta_assets_mpt,
      pz_assets_proofs,
    )
  expect pz_flags_valid

  True
}

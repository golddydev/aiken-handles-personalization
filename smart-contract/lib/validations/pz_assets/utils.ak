use aiken/merkle_patricia_forestry as mpt
use aiken/transaction.{InlineDatum, Input, Output}
use common/cip68.{CIP68Datum, get_image_from_cip68_datum}
use common/collections.{get_single_bytearray_value_from_pairs}
use common/utils.{
  check_output_has_asset_by_asset_id, find_datum_by_user_asset_id,
} as common_utils
use pz_items/utils.{combine_two_pz_flags, default_pz_flags, get_pz_asset_flags}
use validations/pz_assets/types.{PzAssetsProofs}

pub fn get_pz_datum(pz_output: Output) -> CIP68Datum {
  let Output { datum, .. } = pz_output
  expect InlineDatum(inline_datum) = datum
  expect datum: CIP68Datum = inline_datum

  datum
}

// This function checks
// `bg_asset` is User Token or RFT if `bg_image`is set.
// `bg_image` match with `bg_asset` datum's image.
// `pfp_asset` is User Token or RFT if `pfp_image` is set.
// `pfp_image` match with `pfp_asset` datum's image
// `user_output` must have `bg_asset` and `pfp_asset` if `bg_image` and `pfp_image` are set.
//
// returns: (Option<ByteArray>, Option<ByteArray>)
// `bg_asset_id_opt`, `pfp_asset_id_opt`
//
pub fn check_pz_images_and_assets_match(
  extra: Pairs<Data, Data>,
  user_output: Output,
  reference_inputs: List<Input>,
) -> (Option<ByteArray>, Option<ByteArray>) {
  let bg_image_opt = get_single_bytearray_value_from_pairs(extra, "bg_image")
  let bg_asset_id_opt = get_single_bytearray_value_from_pairs(extra, "bg_asset")
  let pfp_image_opt = get_single_bytearray_value_from_pairs(extra, "pfp_image")
  let pfp_asset_id_opt =
    get_single_bytearray_value_from_pairs(extra, "pfp_asset")

  let bg_image_match_with_bg_asset =
    when bg_image_opt is {
      Some(bg_image) -> {
        expect Some(bg_asset_id) = bg_asset_id_opt

        // check user_output has bg_asset
        let has_bg_asset =
          check_output_has_asset_by_asset_id(user_output, bg_asset_id, 1)
        expect has_bg_asset

        // find bg_asset's datum
        let bg_datum_opt =
          find_datum_by_user_asset_id(bg_asset_id, reference_inputs)
        when bg_datum_opt is {
          Some(bg_datum) -> {
            // if bg asset is CIP-68, then bg_image must be same as the one from bg_datum
            let bg_image_from_datum = get_image_from_cip68_datum(bg_datum)
            bg_image == bg_image_from_datum
          }
          None ->
            // if bg asset is CIP-25, we don't check bg_image is same as bg_datum's image
            True
        }
      }
      None -> bg_asset_id_opt == None
    }
  expect bg_image_match_with_bg_asset

  let pfp_image_match_with_pfp_asset =
    when pfp_image_opt is {
      Some(pfp_image) -> {
        expect Some(pfp_asset_id) = pfp_asset_id_opt

        // check user_output has pfp_asset
        let has_pfp_asset =
          check_output_has_asset_by_asset_id(user_output, pfp_asset_id, 1)
        expect has_pfp_asset

        // find pfp_asset's datum
        let pfp_datum_opt =
          find_datum_by_user_asset_id(pfp_asset_id, reference_inputs)
        when pfp_datum_opt is {
          Some(pfp_datum) -> {
            // if pfp asset is CIP-68, then pfp_image must be same as the one from pfp_datum
            let pfp_image_from_datum = get_image_from_cip68_datum(pfp_datum)
            pfp_image == pfp_image_from_datum
          }
          None ->
            // if pfp asset is CIP-25, we don't check pfp_image is same as pfp_datum's image
            True
        }
      }
      None -> pfp_asset_id_opt == None
    }
  expect pfp_image_match_with_pfp_asset

  (bg_asset_id_opt, pfp_asset_id_opt)
}

// This function checks
// `bg_asset` is approved by Policies MPT and Beta Assets MPT
// `pfp_asset` is approved by Policies MPT and Beta Assets MPT
// `nsfw` and `trial` flags are correctly set from `bg_asset` and `pfp_asset` Flags.
//
pub fn check_pz_flags(
  bg_asset_id_opt: Option<ByteArray>,
  pfp_asset_id_opt: Option<ByteArray>,
  nsfw: Int,
  trial: Int,
  policies_mpt: mpt.MerklePatriciaForestry,
  beta_assets_mpt: mpt.MerklePatriciaForestry,
  pz_assets_proofs: PzAssetsProofs,
) -> Bool {
  let (bg_asset_proofs_opt, pfp_asset_proofs_opt) = pz_assets_proofs

  let bg_asset_pz_flags =
    when bg_asset_id_opt is {
      Some(bg_asset_id) -> {
        expect Some(bg_asset_proofs) = bg_asset_proofs_opt

        get_pz_asset_flags(
          bg_asset_id,
          policies_mpt,
          beta_assets_mpt,
          bg_asset_proofs,
        )
      }
      None -> default_pz_flags()
    }
  let pfp_asset_pz_flags =
    when pfp_asset_id_opt is {
      Some(pfp_asset_id) -> {
        expect Some(pfp_asset_proofs) = pfp_asset_proofs_opt

        get_pz_asset_flags(
          pfp_asset_id,
          policies_mpt,
          beta_assets_mpt,
          pfp_asset_proofs,
        )
      }
      None -> default_pz_flags()
    }

  // combine two pz flags
  let pz_flags = combine_two_pz_flags(bg_asset_pz_flags, pfp_asset_pz_flags)

  // check nsfw and trial flags are correctly set from pz flags
  let (nsfw_from_pz_assets, trial_from_pz_assets) = pz_flags

  let nsfw_set_correctly = nsfw == nsfw_from_pz_assets
  let trial_set_correctly = trial == trial_from_pz_assets

  expect nsfw_set_correctly
  expect trial_set_correctly

  True
}

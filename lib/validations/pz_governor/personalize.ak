use aiken/builtin.{b_data, i_data}
use aiken/bytearray
use aiken/cbor
use aiken/int
use aiken/list
use aiken/merkle_patricia_forestry as mpt
use aiken/pairs
use aiken/string
use aiken/transaction.{Input, Output}
use aiken/transaction/value.{PolicyId}
use common/cip68.{CIP68Datum, get_image_from_cip68_datum, prefix_222}
use common/collections.{get_single_value_from_pairs}
use common/hashes.{VerificationKeyHash}
use common/utils.{
  check_output_has_asset_by_asset_id, convert_int_to_bool,
  find_datum_by_user_asset_id, get_attributes_from_datum,
  parse_attribute_key_value,
} as common_utils
use handles/constants.{agreed_terms_url}
use pz_items/types.{PzFlags} as pz_items_types
use pz_items/utils.{combine_two_pz_flags, default_pz_flags, get_pz_asset_flags}
use validations/pz_governor/types.{PzAssetsProofs, PzIndexes}

// - retrieve relevant outputs using pz_indexes
//   ref_output must be not None
pub fn parse_pz_indexes(
  outputs: List<Output>,
  pz_indexes: PzIndexes,
) -> (Output, Option<Output>, Option<Output>, Option<Output>, Option<Output>) {
  let PzIndexes {
    ref_output_index,
    user_output_index,
    treasury_output_index,
    provider_fee_output_index,
    shared_fee_output_index,
  } = pz_indexes

  let ref_output_opt = list.at(outputs, ref_output_index)
  let user_output_opt = list.at(outputs, user_output_index)
  let treasury_output_opt = list.at(outputs, treasury_output_index)
  let provider_fee_output_opt = list.at(outputs, provider_fee_output_index)
  let shared_fee_output_opt = list.at(outputs, shared_fee_output_index)

  expect Some(ref_output) = ref_output_opt
  (
    ref_output,
    user_output_opt,
    treasury_output_opt,
    provider_fee_output_opt,
    shared_fee_output_opt,
  )
}

// - `new_metadata` must have `image` and `mediaType` (as single value)
// - for all keys in `old_metadata` other than `image` and `mediaType`,
//   there must be a corresponding key in `new_metadata` with same value.
//
// returns: (new_image, new_media_type)
//
pub fn check_new_metadata(
  old_metadata: Pairs<Data, Data>,
  new_metadata: Pairs<Data, Data>,
) -> (ByteArray, ByteArray) {
  // immutable values
  let new_image_value = get_single_value_from_pairs(new_metadata, "image")
  let new_media_type_value =
    get_single_value_from_pairs(new_metadata, "mediaType")

  expect Some(new_image_data) = new_image_value
  expect new_image: ByteArray = new_image_data
  expect Some(new_media_type_data) = new_media_type_value
  expect new_media_type: ByteArray = new_media_type_data

  let immutables_stay_same =
    old_metadata
      |> pairs.foldl(
          True,
          fn(key, value, acc) -> Bool {
            acc && if key == b_data("image") || key == b_data("mediaType") {
              True
            } else {
              let new_value_opt = pairs.get_first(new_metadata, key)
              let immutable_stay_same = new_value_opt == Some(value)
              if immutable_stay_same {
                True
              } else {
                trace string.concat(
                  @"immutable metadata changed: ",
                  cbor.diagnostic(key),
                )
                False
              }
            }
          },
        )
  expect immutables_stay_same

  (new_image, new_media_type)
}

// - both `old_extra` and `new_extra` must be in Pairs<Data, Data> format.
// - transaction must be signed by `validated_by` if it is set as single value.
// - `standard_image`, `standard_image_hash`, `original_address` must be same as `old_extra`. (as single value or None)
// - `agreed_terms` must be same as `agreed_terms_url`.
// - `last_edited_time` must be same as transaction's start time.
//
// returns: (old_last_edited_time_opt, new_extra)
//
pub fn check_new_extra(
  old_extra_data: Data,
  new_extra_data: Data,
  extra_signatories: List<VerificationKeyHash>,
  transaction_start_time: Int,
) -> (Option<Int>, Pairs<Data, Data>) {
  expect new_extra: Pairs<Data, Data> = new_extra_data
  expect old_extra: Pairs<Data, Data> = old_extra_data

  // tansaction must be signed by `validated_by` if it is set as single value.
  let validated_by_value =
    get_single_value_from_pairs(new_extra, "validated_by")
  let validated_by_opt =
    when validated_by_value is {
      None -> None
      Some(validated_by_data) -> {
        expect validated_by: VerificationKeyHash = validated_by_data
        Some(validated_by)
      }
    }
  let is_tx_signed_by_validated_by =
    when validated_by_opt is {
      None -> True
      Some(validated_by) -> list.has(extra_signatories, validated_by)
    }
  expect is_tx_signed_by_validated_by

  // - `standard_image`, `standard_image_hash`, `original_address` must be same as `old_extra`. (as single value or None)
  let immutables_stay_same =
    ["standard_image", "standard_image_hash", "original_address"]
      |> list.all(
          fn(key) -> Bool {
            let new_value = get_single_value_from_pairs(new_extra, key)
            let old_value = get_single_value_from_pairs(old_extra, key)
            let immutable_stay_same = new_value == old_value

            if immutable_stay_same {
              True
            } else {
              trace string.concat(
                @"immutable extra changed: ",
                cbor.diagnostic(key),
              )
              False
            }
          },
        )
  expect immutables_stay_same

  // `agreed_terms` must be same as `"https://handle.me/$/tou"`.
  let agreed_terms_value =
    get_single_value_from_pairs(new_extra, "agreed_terms")
  expect Some(last_edited_time_data) = agreed_terms_value
  expect agreed_terms: ByteArray = last_edited_time_data
  let is_agreed_terms_valid = agreed_terms == agreed_terms_url
  expect is_agreed_terms_valid

  // `last_edited_time` must be same as transaction validity range's lower bound.
  let last_edited_time_value =
    get_single_value_from_pairs(new_extra, "last_edited_time")
  expect Some(last_edited_time_data) = last_edited_time_value
  expect last_edited_time: Int = last_edited_time_data
  let is_last_edited_time_valid = last_edited_time == transaction_start_time
  expect is_last_edited_time_valid

  // get `last_edited_time` from old datum's extra
  let old_last_edited_time_value =
    pairs.get_first(old_extra, b_data("last_edited_time"))
  let old_last_edited_time_opt =
    when old_last_edited_time_value is {
      None -> None
      Some(old_last_edited_time_data) -> {
        expect old_last_edited_time: Int = old_last_edited_time_data
        Some(old_last_edited_time)
      }
    }

  (old_last_edited_time_opt, new_extra)
}

// this function checks whether new_datum is reset or not (same as initial value)
// returns: Bool
//
pub fn check_new_datum_reset(
  new_extra: Pairs<Data, Data>,
  new_image: ByteArray,
) -> Bool {
  let new_image_hash_value =
    get_single_value_from_pairs(new_extra, "image_hash")
  let new_standard_image_value =
    get_single_value_from_pairs(new_extra, "standard_image")
  let new_standard_image_hash_value =
    get_single_value_from_pairs(new_extra, "standard_image_hash")
  let new_bg_image_value = get_single_value_from_pairs(new_extra, "bg_image")
  let new_pfp_image_value = get_single_value_from_pairs(new_extra, "pfp_image")
  let new_bg_asset_value = get_single_value_from_pairs(new_extra, "bg_asset")
  let new_pfp_asset_value = get_single_value_from_pairs(new_extra, "pfp_asset")

  // is `designer` set
  let new_designer_value = get_single_value_from_pairs(new_extra, "designer")
  let is_designed = new_designer_value != None

  // get pz flags
  let new_nsfw_value = get_single_value_from_pairs(new_extra, "nsfw")
  let new_trial_value = get_single_value_from_pairs(new_extra, "trial")

  let is_new_datum_reset = and {
      Some(b_data(new_image)) == new_standard_image_value,
      new_image_hash_value == new_standard_image_hash_value,
      new_bg_image_value == None,
      new_pfp_image_value == None,
      new_bg_asset_value == None,
      new_pfp_asset_value == None,
      is_designed == False,
      Some(i_data(0)) == new_nsfw_value,
      Some(i_data(0)) == new_trial_value,
    }
  is_new_datum_reset
}

// This Function checks
// - bg_asset and pfp_asset's PzFlags from Policies MPT and Beta Assets MPT
// - bg_asset and pfp_asset must be user token or RFT
// - bg_image and pfp_image must be same as bg_asset and pfp_asset's datum's image
// - user_output must have bg_asset and pfp_asset if they are set.
//
// returns: (PzFlags, Option<CIP68Datum>, Option<ByteArray>, Option<ByteArray>)
// PzFlags, Bg Datum, bg_asset_id_opt, pfp_asset_id_opt
//
pub fn check_pz_assets(
  extra: Pairs<Data, Data>,
  policies_mpt: mpt.MerklePatriciaForestry,
  beta_assets_mpt: mpt.MerklePatriciaForestry,
  pz_assets_proofs: PzAssetsProofs,
  user_output_opt: Option<Output>,
  reference_inputs: List<Input>,
) -> (PzFlags, Option<CIP68Datum>, Option<ByteArray>, Option<ByteArray>) {
  let (bg_asset_proofs_opt, pfp_asset_proofs_opt) = pz_assets_proofs

  let bg_asset_data_opt = get_single_value_from_pairs(extra, "bg_asset")
  let bg_image_data_opt = get_single_value_from_pairs(extra, "bg_image")
  let pfp_asset_data_opt = get_single_value_from_pairs(extra, "pfp_asset")
  let pfp_image_data_opt = get_single_value_from_pairs(extra, "pfp_image")

  // get bg asset's PzFlags
  let (bg_asset_pz_flags, bg_datum_opt, bg_asset_id_opt) =
    when bg_image_data_opt is {
      Some(bg_image_data) -> {
        expect bg_image: ByteArray = bg_image_data

        // if bg_image is set then bg_asset must be set
        expect Some(bg_asset_id_data) = bg_asset_data_opt
        expect bg_asset_id: ByteArray = bg_asset_id_data
        expect Some(bg_asset_proofs) = bg_asset_proofs_opt

        let bg_asset_pz_flags =
          get_pz_asset_flags(
            bg_asset_id,
            policies_mpt,
            beta_assets_mpt,
            bg_asset_proofs,
          )

        // check bg_image is same as bg_asset's datum's image
        let bg_datum_opt =
          find_datum_by_user_asset_id(bg_asset_id, reference_inputs)
        let bg_image_match_with_bg_datum =
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
        expect bg_image_match_with_bg_datum

        // check user_output has bg_asset
        expect Some(user_output) = user_output_opt
        let has_bg_asset =
          check_output_has_asset_by_asset_id(user_output, bg_asset_id, 1)
        expect has_bg_asset

        (bg_asset_pz_flags, bg_datum_opt, Some(bg_asset_id))
      }
      None -> {
        // if bg_image is NOT set, then bg_asset must be NOT set
        expect bg_asset_data_opt == None
        (default_pz_flags(), None, None)
      }
    }

  // get pfp asset's PzFlags
  let (pfp_asset_pz_flags, pfp_asset_id_opt) =
    when pfp_image_data_opt is {
      Some(pfp_image_data) -> {
        expect pfp_image: ByteArray = pfp_image_data

        // if pfp_image is set then pfp_asset must be set
        expect Some(pfp_asset_id_data) = pfp_asset_data_opt
        expect pfp_asset_id: ByteArray = pfp_asset_id_data
        expect Some(pfp_asset_proofs) = pfp_asset_proofs_opt

        let pfp_asset_pz_flags =
          get_pz_asset_flags(
            pfp_asset_id,
            policies_mpt,
            beta_assets_mpt,
            pfp_asset_proofs,
          )

        // check pfp_image is same as pfp_asset's datum's image
        let pfp_datum_opt =
          find_datum_by_user_asset_id(pfp_asset_id, reference_inputs)
        let pfp_image_match_with_pfp_datum =
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
        expect pfp_image_match_with_pfp_datum

        // check user_output has pfp_asset
        expect Some(user_output) = user_output_opt
        let has_pfp_asset =
          check_output_has_asset_by_asset_id(user_output, pfp_asset_id, 1)
        expect has_pfp_asset

        (pfp_asset_pz_flags, Some(pfp_asset_id))
      }
      None -> {
        // if pfp_image is NOT set, then pfp_asset must be NOT set
        expect pfp_asset_data_opt == None
        (default_pz_flags(), None)
      }
    }
  let pz_flags = combine_two_pz_flags(bg_asset_pz_flags, pfp_asset_pz_flags)

  (pz_flags, bg_datum_opt, bg_asset_id_opt, pfp_asset_id_opt)
}

// this function checks bg asset's constraints are met
// returns: Bool
//
pub fn check_bg_asset_constraints(
  bg_datum: CIP68Datum,
  user_output_opt: Option<Output>,
  reference_inputs: List<Input>,
  extra_signatories: List<VerificationKeyHash>,
  pfp_asset_id_opt: Option<ByteArray>,
  policy_id: PolicyId,
  handle_name: ByteArray,
) -> Bool {
  // this extra is `default`
  let CIP68Datum { extra, .. } = bg_datum
  expect bg_datum_extra: Pairs<Data, Data> = extra

  // check `required_signature` from `bg_datum`'s extra
  let required_signature_value =
    get_single_value_from_pairs(bg_datum_extra, "required_signature")
  let is_tx_signed_by_required_signature =
    when required_signature_value is {
      None -> True
      Some(required_signature_data) -> {
        expect required_signature: VerificationKeyHash = required_signature_data
        list.has(extra_signatories, required_signature)
      }
    }
  expect is_tx_signed_by_required_signature

  // check `require_asset_collections`, `require_asset_attributes` and `require_asset_displayed`
  let required_asset_collections_value =
    get_single_value_from_pairs(bg_datum_extra, "required_asset_collections")
  let required_asset_attributes_value =
    get_single_value_from_pairs(bg_datum_extra, "required_asset_attributes")
  let required_asset_displayed_value =
    get_single_value_from_pairs(bg_datum_extra, "required_asset_displayed")
  when required_asset_collections_value is {
    None ->
      // if `required_asset_collections` is not set, there is not bg asset constraints
      True
    Some(required_asset_collections_data) -> {
      // `required_asset_collections` must be List<ByteArray> when it is set.
      // This is a list of Asset Ids
      expect required_asset_collections: List<ByteArray> =
        required_asset_collections_data

      // there must be user_output
      expect Some(user_output) = user_output_opt

      // for any of those assets
      required_asset_collections
        |> list.any(
            fn(required_asset_id) -> Bool {
              // check user_output has required asset
              let user_output_has_required_asset =
                check_output_has_asset_by_asset_id(
                  user_output,
                  required_asset_id,
                  1,
                )

              // check required_asset_attributes
              let required_asset_attributes_met =
                when required_asset_attributes_value is {
                  None -> True
                  Some(required_asset_attributes_data) -> {
                    expect required_asset_attributes: List<ByteArray> =
                      required_asset_attributes_data
                    check_required_asset_attributes(
                      required_asset_id,
                      required_asset_attributes,
                      reference_inputs,
                    )
                  }
                }

              // check `required_asset_displayed`
              let must_display =
                when required_asset_displayed_value is {
                  None -> True
                  Some(required_asset_displayed_data) -> {
                    expect required_asset_displayed: Int =
                      required_asset_displayed_data
                    convert_int_to_bool(required_asset_displayed)
                  }
                }
              let required_asset_displayed_met =
                when must_display is {
                  True -> {
                    // pfp_asset must be required_asset OR current handle (being personalized) is required_asset
                    let is_pfp_asset_required_asset =
                      pfp_asset_id_opt == Some(required_asset_id)
                    let user_handle_asset_name =
                      bytearray.concat(prefix_222, handle_name)
                    let user_handle_asset_id =
                      bytearray.concat(policy_id, user_handle_asset_name)
                    let is_handle_required_asset =
                      user_handle_asset_id == required_asset_id
                    let required_asset_displayed_met = or {
                        is_pfp_asset_required_asset,
                        is_handle_required_asset,
                      }
                    required_asset_displayed_met
                  }
                  False ->
                    // we don't check when flag is False
                    True
                }
              let required_asset_met = and {
                  user_output_has_required_asset,
                  required_asset_attributes_met,
                  required_asset_displayed_met,
                }
              required_asset_met
            },
          )
    }
  }
}

// This function checks 
// required_asset's datum (required_asset is User Token or RFT, so there must be reference token in reference inputs)
// has all required_asset_attributes (List<ByteArray>, each ByteArray is `key:value` in utf8 format)
// NOTE:
// `required_asset_id` must be User Token or RFT
//
fn check_required_asset_attributes(
  required_asset_id: ByteArray,
  required_asset_attributes: List<ByteArray>,
  reference_inputs: List<Input>,
) -> Bool {
  let required_asset_datum_opt =
    find_datum_by_user_asset_id(required_asset_id, reference_inputs)
  when required_asset_datum_opt is {
    Some(required_asset_datum) -> {
      let attributes = get_attributes_from_datum(required_asset_datum)
      // for all required_asset_attributes
      required_asset_attributes
        |> list.all(
            fn(required_asset_attribute: ByteArray) -> Bool {
              let (required_key, required_value, attribute_string) =
                parse_attribute_key_value(required_asset_attribute)
              let value = get_single_value_from_pairs(attributes, required_key)
              let attribute_value_match =
                check_attribute_value_with_data(required_value, value)
              when attribute_value_match is {
                True -> True
                False -> {
                  trace string.concat(
                    @"required_asset_attribute not met: ",
                    attribute_string,
                  )
                  False
                }
              }
            },
          )
    }
    None ->
      // when required_asset is CIP25, we couldn't check required_asset_attributes
      // we just approve it
      True
  }
}

// This function checks
// `value` match with `required_value`
// when `required_value` is valid Int (in utf8 format), value must be Int
// when `required_value` is not-empty ByteArray, `value` must be ByteArray with same value
// when `required_value` is `#""`, `value` must be None or empty ByteArray
//
fn check_attribute_value_with_data(
  required_value: ByteArray,
  value: Option<Data>,
) -> Bool {
  let required_int_valude_opt = int.from_utf8(required_value)

  when required_int_valude_opt is {
    Some(required_int_value) -> value == Some(i_data(required_int_value))
    None -> {
      let is_empty_value = bytearray.length(required_value) == 0
      when is_empty_value is {
        True -> or {
            value == None,
            value == Some(b_data("")),
          }
        False -> value == Some(b_data(required_value))
      }
    }
  }
}

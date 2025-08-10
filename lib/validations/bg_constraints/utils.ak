use aiken/builtin.{b_data, i_data}
use aiken/bytearray
use aiken/int
use aiken/list
use aiken/option
use aiken/string
use aiken/transaction.{InlineDatum, Input, Output}
use aiken/transaction/value.{PolicyId}
use common/assets.{AssetClass}
use common/cip68.{CIP68Datum, prefix_222}
use common/collections.{
  get_single_bytearray_value_from_pairs, get_single_int_value_from_pairs,
  get_single_list_bytearray_value_from_pairs, get_single_value_from_pairs,
}
use common/hashes.{VerificationKeyHash}
use common/utils.{
  check_output_has_asset_by_asset_id, convert_int_to_bool,
  find_datum_by_user_asset_id, get_attributes_from_datum,
  parse_attribute_key_value,
} as common_utils

// This function checks
// pz_output have only one asset (without lovelace) with given asset_class
// returns: CIP68Datum (new_datum)
//
// NOTE:
// This function actually checks asset_class is valid,
// since pz_output is validated from `pz_governor` validator.
//
pub fn check_pz_output_has_only_asset_class(
  pz_output: Output,
  asset_class: AssetClass,
) -> CIP68Datum {
  let Output { value: v, datum, .. } = pz_output
  let (policy_id, asset_name) = asset_class

  let have_only_asset_class =
    value.without_lovelace(v) == (
      value.zero()
        |> value.add(policy_id, asset_name, 1)
    )
  expect have_only_asset_class

  // get CIP68Datum from pz_output
  expect InlineDatum(inline_datum) = datum
  expect datum: CIP68Datum = inline_datum

  datum
}

// This function gets bg_datum from handle's CIP68Datum
// If handle has bg_asset 
// NOTE: bg_asset must be valid User Asset Id or RFT
//   - if bg_asset is CIP68, there must be valid CIP68Datum for bg_asset
//   - otherwise return None
// Otherwise return None
//
pub fn get_bg_asset_datum(
  datum: CIP68Datum,
  reference_inputs: List<Input>,
) -> Option<CIP68Datum> {
  let CIP68Datum { extra, .. } = datum
  expect extra: Pairs<Data, Data> = extra

  let bg_asset_id_opt = get_single_bytearray_value_from_pairs(extra, "bg_asset")
  when bg_asset_id_opt is {
    None -> None
    Some(bg_asset_id) -> {
      // find CIP68Datum for bg_asset_id
      let bg_datum_opt =
        find_datum_by_user_asset_id(bg_asset_id, reference_inputs)
      bg_datum_opt
    }
  }
}

// this function checks bg asset's constraints are met
// returns: Bool
//
pub fn check_bg_constraints_are_met(
  bg_datum: CIP68Datum,
  user_output: Output,
  reference_inputs: List<Input>,
  extra_signatories: List<VerificationKeyHash>,
  policy_id: PolicyId,
  handle_name: ByteArray,
  pfp_asset_id_opt: Option<ByteArray>,
) -> Bool {
  // this extra is `default`
  let CIP68Datum { extra, .. } = bg_datum
  expect bg_datum_extra: Pairs<Data, Data> = extra

  // check `required_signature` from `bg_datum`'s extra
  let required_signature_opt =
    get_single_bytearray_value_from_pairs(bg_datum_extra, "required_signature")
  let is_tx_signed_by_required_signature =
    when required_signature_opt is {
      None -> True
      Some(required_signature) ->
        list.has(extra_signatories, required_signature)
    }
  expect is_tx_signed_by_required_signature

  // check `require_asset_collections`, `require_asset_attributes` and `require_asset_displayed`
  let required_asset_collections_opt =
    get_single_list_bytearray_value_from_pairs(
      bg_datum_extra,
      "required_asset_collections",
    )
  let required_asset_attributes_opt =
    get_single_list_bytearray_value_from_pairs(
      bg_datum_extra,
      "required_asset_attributes",
    )

  let required_asset_displayed =
    get_single_int_value_from_pairs(bg_datum_extra, "required_asset_displayed")
      |> option.map(convert_int_to_bool)
      |> option.or_else(False)

  when required_asset_collections_opt is {
    None ->
      // if `required_asset_collections` is not set, there is not bg asset constraints
      True
    Some(required_asset_collections) ->
      // for any of those assets
      required_asset_collections
        |> list.any(fn(required_asset_id: ByteArray) -> Bool { and {
                // check user_output has required asset
                check_output_has_asset_by_asset_id(
                  user_output,
                  required_asset_id,
                  1,
                ),
                //
                // check required_asset_attributes
                when required_asset_attributes_opt is {
                  None -> True
                  Some(required_asset_attributes) ->
                    check_required_asset_attributes(
                      required_asset_id,
                      required_asset_attributes,
                      reference_inputs,
                    )
                },
                //
                // check `required_asset_displayed`
                when required_asset_displayed is {
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
                },
              } })
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
                check_attribute_value(value, required_value)
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
fn check_attribute_value(value: Option<Data>, required_value: ByteArray) -> Bool {
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

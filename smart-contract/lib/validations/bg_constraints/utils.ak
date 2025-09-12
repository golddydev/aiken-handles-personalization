use aiken/builtin.{b_data, i_data}
use aiken/bytearray
use aiken/cbor.{diagnostic, serialise}
use aiken/hash.{sha2_256}
use aiken/int
use aiken/list
use aiken/option
use aiken/pairs
use aiken/string
use aiken/transaction.{InlineDatum, Input, Output}
use aiken/transaction/value.{PolicyId}
use common/assets.{AssetClass}
use common/base58.{base58_to_hash}
use common/cip68.{CIP68Datum, prefix_222}
use common/collections.{
  get_single_bytearray_value_from_pairs,
  get_single_int_as_bool_value_from_bytearray_pairs,
  get_single_int_as_bool_value_from_pairs,
  get_single_int_value_from_bytearray_pairs,
  get_single_list_bytearray_value_from_bytearray_pairs,
  get_single_list_bytearray_value_from_pairs,
  get_single_value_from_bytearray_pairs, get_single_value_from_pairs,
}
use common/hashes.{VerificationKeyHash}
use common/utils.{
  check_output_has_asset_by_asset_id, find_datum_by_user_asset_id,
  get_attributes_from_datum, parse_attribute_key_value,
} as common_utils
use validations/bg_constraints/properties.{
  get_exclusive_keys, get_plural_keys, get_qr_keys, get_simple_keys,
  should_check_with_plural_properties,
}
use validations/bg_constraints/types.{FontShadowSize, PfpOffset}

const square_bytearray_for_qr_value: ByteArray = "square,"

// This function checks
// pz_output have only one asset (without lovelace) with given asset_class
// returns: CIP68Datum (new_datum)
//
// NOTE:
// This function actually checks asset_class from redeemer is correct one,
// since pz_output is validated from `pz_governor` validator.
//
pub fn check_pz_output_has_only_asset_class(
  pz_output: Output,
  asset_class: AssetClass,
) -> CIP68Datum {
  let Output { value: v, datum, .. } = pz_output
  let AssetClass { policy_id, asset_name } = asset_class

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

  get_single_bytearray_value_from_pairs(extra, "bg_asset")
    |> option.map(
        fn(bg_asset_id) -> Option<CIP68Datum> {
          // find CIP68Datum for bg_asset_id
          let bg_datum_opt =
            find_datum_by_user_asset_id(bg_asset_id, reference_inputs)
          bg_datum_opt
        },
      )
    |> option.flatten
}

// this function checks bg asset's required settings are met
// returns: Bool
//
pub fn check_bg_required_settings_are_met(
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
  let is_tx_signed_by_required_signature =
    get_single_bytearray_value_from_pairs(bg_datum_extra, "required_signature")
      |> option.map(
          fn(required_signature) -> Bool {
            list.has(extra_signatories, required_signature)
          },
        )
      |> option.or_else(True)
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
    get_single_int_as_bool_value_from_pairs(
      bg_datum_extra,
      "required_asset_displayed",
    )

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
                required_asset_attributes_opt
                  |> option.map(
                      fn(required_asset_attributes) -> Bool {
                        check_required_asset_attributes(
                          required_asset_id,
                          required_asset_attributes,
                          reference_inputs,
                        )
                      },
                    )
                  |> option.or_else(True),
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

// This function checks designer settings are set correctly.
// * We receive designer_settings from redeemer and check its hash is same as new_designer
// * Check all settings from designer_settings are correct against default_settings from bg_datum
//
pub fn check_designer_settings(
  designer_settings: Pairs<ByteArray, Data>,
  default_settings_opt: Option<Pairs<ByteArray, Data>>,
  new_designer: ByteArray,
) -> Bool {
  // check designer_settings hash is same as new_designer's origin hash
  // new_designer is IPFS URL e.g. ipfs://z...
  // we drop those `ipfs://z` and check with CID (base58 encoded)
  let multihash = base58_to_hash(bytearray.drop(new_designer, 8))
  // drop 4 bytes from multihash, 
  let original_hash = bytearray.drop(multihash, 4)

  let designer_settings_hash = sha2_256(serialise(designer_settings))
  let designer_hash_match = designer_settings_hash == original_hash
  expect designer_hash_match

  // check `force_creator_settings` is enabled
  let forced_enabled =
    get_single_int_as_bool_value_from_bytearray_pairs(
      designer_settings,
      "force_creator_settings",
    )

  let plural_keys = get_plural_keys()
  let exclusive_keys = get_exclusive_keys()
  let qr_keys = get_qr_keys()
  let simple_keys = get_simple_keys()

  // check all settings from designer_settings are correct against default_settings
  let designer_settings_valid =
    designer_settings
      |> pairs.foldl(True, fn(key, value, acc) -> Bool { and {
              acc,
              {
                let (check_with_plural_key, plural_key) =
                  should_check_with_plural_properties(plural_keys, key)
                if check_with_plural_key {
                  let default_value_opt =
                    get_default_value_opt(default_settings_opt, plural_key)
                  let is_plural_value_valid =
                    check_property_in_default_array(
                      value,
                      default_value_opt,
                      forced_enabled,
                    )
                  trace string.concat(
                    diagnostic(key),
                    @": check as plural property",
                  )
                  expect is_plural_value_valid
                  True
                } else if list.has(exclusive_keys, key) {
                  trace string.concat(
                    diagnostic(key),
                    @": check as exclusive property",
                  )
                  let is_exclusive_value_valid =
                    check_property_same_as_default_value(
                      value,
                      get_default_value_opt(default_settings_opt, key),
                      forced_enabled,
                      True,
                    )
                  expect is_exclusive_value_valid
                  True
                } else if list.has(qr_keys, key) {
                  trace string.concat(
                    diagnostic(key),
                    @": check as qr property",
                  )
                  let is_qr_value_valid =
                    check_qr_property(
                      value,
                      get_default_value_opt(default_settings_opt, key),
                      forced_enabled,
                    )
                  expect is_qr_value_valid
                  True
                } else if list.has(simple_keys, key) {
                  trace string.concat(
                    diagnostic(key),
                    @": check as simple property",
                  )
                  let is_simple_value_valid =
                    check_property_same_as_default_value(
                      value,
                      get_default_value_opt(default_settings_opt, key),
                      forced_enabled,
                      False,
                    )
                  expect is_simple_value_valid
                  True
                } else if key == "font_shadow_size" {
                  trace string.concat(
                    diagnostic(key),
                    @": check as font_shadow_size",
                  )
                  let is_valid_with_default_value =
                    check_property_same_as_default_value(
                      value,
                      get_default_value_opt(default_settings_opt, key),
                      forced_enabled,
                      False,
                    )
                  expect is_valid_with_default_value

                  // check font_shadow_size is valid Type
                  let is_font_shadow_size_valid =
                    check_font_shadow_size_data(value)
                  expect is_font_shadow_size_valid
                  True
                } else if key == "pfp_zoom" {
                  trace string.concat(diagnostic(key), @": check as pfp_zoom")
                  let is_valid_with_default_value =
                    check_property_same_as_default_value(
                      value,
                      get_default_value_opt(default_settings_opt, key),
                      forced_enabled,
                      False,
                    )
                  expect is_valid_with_default_value

                  // check pfp_zoom is valid Type
                  let is_pfp_zoom_valid = check_pfp_zoom_data(value)
                  expect is_pfp_zoom_valid
                  True
                } else if key == "pfp_offset" {
                  trace string.concat(diagnostic(key), @": check as pfp_offset")
                  let is_valid_with_default_value =
                    check_property_same_as_default_value(
                      value,
                      get_default_value_opt(default_settings_opt, key),
                      forced_enabled,
                      False,
                    )
                  expect is_valid_with_default_value

                  // check pfp_offset with pfp_zoom value
                  // pfp_offset value must be Int between [-off_set_max, +off_set_max]
                  let max_offset = get_pfp_max_offset(designer_settings)
                  let is_pfp_offset_valid =
                    check_pfp_offset_data(value, max_offset)
                  expect is_pfp_offset_valid
                  True
                } else {
                  True
                }
              },
            } })
  expect designer_settings_valid

  let is_ribbon_colors_valid =
    check_text_ribbon_colors(
      designer_settings,
      default_settings_opt,
      forced_enabled,
    )
  expect is_ribbon_colors_valid

  True
}

fn check_text_ribbon_colors(
  designer_settings: Pairs<ByteArray, Data>,
  default_settings_opt: Option<Pairs<ByteArray, Data>>,
  forced_enabled: Bool,
) -> Bool {
  let default_ribbon_gradient_opt =
    get_default_value_opt(default_settings_opt, "text_ribbon_gradient")
  let default_ribbon_colors_opt =
    get_default_value_opt(default_settings_opt, "text_ribbon_colors")
  let ribbon_colors =
    get_single_list_bytearray_value_from_bytearray_pairs(
      designer_settings,
      "text_ribbon_colors",
    )
      |> option.or_else([])
  let ribbon_colors_count = list.length(ribbon_colors)

  let is_default_gradient =
    default_ribbon_gradient_opt
      |> option.map(check_gradient_data)
      |> option.or_else(False)
  let default_ribbon_colors =
    default_ribbon_colors_opt
      |> option.map(
          fn(default_ribbon_colors) -> List<ByteArray> {
            expect default_ribbon_colors: List<ByteArray> =
              default_ribbon_colors
            default_ribbon_colors
          },
        )
      |> option.or_else([])
  let default_ribbon_colors_count = list.length(default_ribbon_colors)

  // when no creator's default ribbon colors or forced_enabled is False
  // any single ribbon color is valid
  let pass_check = and {
      or {
        !forced_enabled,
        default_ribbon_colors_count == 0,
      },
      ribbon_colors_count <= 1,
    }

  when pass_check is {
    True -> True
    False ->
      when is_default_gradient is {
        True -> {
          trace @"creator default gradient set"
          let is_same_as_default = default_ribbon_colors == ribbon_colors
          expect is_same_as_default
          True
        }
        False -> {
          trace @"creator default gradient not set"
          // must have single ribbon color
          // and that must be in default_ribbon_colors
          when ribbon_colors is {
            [ribbon_color] -> {
              let one_of_default_colors =
                list.any(
                  default_ribbon_colors,
                  fn(color) -> Bool { color == ribbon_color },
                )
              expect one_of_default_colors
              True
            }
            _ -> {
              trace @"must have single ribbon color"
              False
            }
          }
        }
      }
  }
}

fn check_property_in_default_array(
  value: Data,
  default_value_opt: Option<Data>,
  forced_enabled: Bool,
) -> Bool {
  let is_default_none = default_value_opt == None
  let pass_check = or {
      is_default_none,
      !forced_enabled,
    }
  when pass_check is {
    True -> True
    False -> {
      // default array data must be List<ByteArray>
      expect Some(default_array) = default_value_opt
      expect default_array: List<ByteArray> = default_array

      // property value must be ByteArray
      expect value: ByteArray = value

      let is_property_in_default_array = list.has(default_array, value)
      is_property_in_default_array
    }
  }
}

fn check_property_same_as_default_value(
  value: Data,
  default_value_opt: Option<Data>,
  forced_enabled: Bool,
  exclusive: Bool,
) -> Bool {
  let is_same_as_default_value = Some(value) == default_value_opt
  when is_same_as_default_value is {
    True -> True
    False -> {
      let pass_forced_check = or {
          forced_enabled == False,
          default_value_opt == None,
        }
      let is_empty_value = or {
          value == b_data(""),
          value == i_data(0),
        }
      let pass_exclusive_check = or {
          exclusive == False,
          is_empty_value,
        }
      and {
        pass_forced_check,
        pass_exclusive_check,
      }
    }
  }
}

fn check_qr_property(
  value: Data,
  default_value_opt: Option<Data>,
  forced_enabled: Bool,
) -> Bool {
  let is_same_as_default_value = Some(value) == default_value_opt
  when is_same_as_default_value is {
    True -> True
    False -> {
      // property value must be ByteArray
      expect value: ByteArray = value

      let can_start_with_square = or {
          default_value_opt == None,
          forced_enabled == False,
        }
      and {
        can_start_with_square,
        does_start_with_square(value),
      }
    }
  }
}

fn get_default_value_opt(
  default_settings_opt: Option<Pairs<ByteArray, Data>>,
  key: ByteArray,
) -> Option<Data> {
  default_settings_opt
    |> option.and_then(
        fn(default_settings) {
          get_single_value_from_bytearray_pairs(default_settings, key)
        },
      )
}

fn does_start_with_square(value: ByteArray) -> Bool {
  bytearray.take(value, bytearray.length(square_bytearray_for_qr_value)) == square_bytearray_for_qr_value
}

fn check_font_shadow_size_data(value: Data) -> Bool {
  expect value: FontShadowSize = value

  let (x, y, blur) = value
  let is_x_valid = x >= -20 && x <= 20
  let is_y_valid = y >= -20 && y <= 20
  let is_blur_valid = blur >= 0 && blur <= 20

  expect is_x_valid
  expect is_y_valid
  expect is_blur_valid

  True
}

fn check_pfp_zoom_data(value: Data) -> Bool {
  expect zoom: Int = value

  let is_zoom_valid = zoom >= 100 && zoom <= 200
  expect is_zoom_valid
  True
}

fn check_pfp_offset_data(value: Data, max_offset: Int) -> Bool {
  expect offset: PfpOffset = value
  let (x, y) = offset
  let is_x_valid = x >= -max_offset && x <= max_offset
  let is_y_valid = y >= -max_offset && y <= max_offset
  expect is_x_valid
  expect is_y_valid
  True
}

fn get_pfp_max_offset(designer_settings: Pairs<ByteArray, Data>) -> Int {
  let pfp_zoom_opt =
    get_single_int_value_from_bytearray_pairs(designer_settings, "pfp_zoom")
  when pfp_zoom_opt is {
    None -> 0
    Some(pfp_zoom) -> {
      // pfp_zoom must be bigger than or equal to 100
      expect pfp_zoom >= 100
      let pfp_zoom_diff = pfp_zoom - 100

      576 * pfp_zoom_diff / 200
    }
  }
}

// check value is valid gradient value or not
// valid value should be either "radial" or "linear"
fn check_gradient_data(value: Data) -> Bool {
  or {
    value == b_data("radial"),
    value == b_data("linear"),
  }
}

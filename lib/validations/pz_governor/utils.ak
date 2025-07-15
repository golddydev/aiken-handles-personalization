use aiken/builtin.{b_data}
use aiken/bytearray
use aiken/cbor
use aiken/dict
use aiken/list
use aiken/pairs
use aiken/string
use aiken/transaction.{InlineDatum, Input, Output}
use aiken/transaction/value.{AssetName, PolicyId, Value}
use common/assets.{AssetClass}
use common/cip68.{
  CIP68Datum, is_reference_asset_name, is_virtual_subhandle_asset_name,
  prefix_000, prefix_100,
}
use handles/types.{Handle,
  NFTHandle, NFTSubhandle, VirtualSubhandle} as handles_types
use handles/utils.{parse_handle_name}
use validations/pz_governor/types.{PzIndexes}

// - Finds the personalizing UTxO `pz_utxo`
//   UTxO with Reference Handle or Virtual Subhandle Asset.
//   Handle Assets can have several policy ids.
// - `pz_utxo` must have only one Asset of the given `asset_class` from redeemer.
// - `pz_utxo` datum must be in CIP68Datum format.
//
pub fn find_pz_utxo(
  inputs: List<Input>,
  policy_ids: List<PolicyId>,
  asset_class: AssetClass,
) -> (Output, CIP68Datum) {
  let pz_inputs =
    inputs
      |> list.filter(
          fn(input) -> Bool {
            let Input { output: Output { value: utxo_value, .. }, .. } = input
            does_value_has_reference_handle_asset_or_virtual_subhandle_asset(
              utxo_value,
              policy_ids,
            )
          },
        )

  // `pz_utxo` must have only one Asset of the given `asset_class` from redeemer.
  expect [pz_input] = pz_inputs
  let Input { output: pz_output, .. } = pz_input
  let Output { value: pz_utxo_value, datum, .. } = pz_output

  // must have only one Asset of the given `asset_class` from redeemer
  let (policy_id, asset_name) = asset_class
  let has_only_once_asset =
    value.without_lovelace(pz_utxo_value) == (
      value.zero()
        |> value.add(policy_id, asset_name, 1)
    )
  expect has_only_once_asset

  // `pz_utxo` datum must be in CIP68Datum format.
  expect InlineDatum(datum) = datum
  expect cip68_datum: CIP68Datum = datum

  (pz_output, cip68_datum)
}

fn does_value_has_reference_handle_asset_or_virtual_subhandle_asset(
  v: Value,
  policy_ids: List<PolicyId>,
) -> Bool {
  policy_ids
    |> list.any(
        fn(policy_id) -> Bool {
          let token_pairs = v |> value.tokens(policy_id) |> dict.to_pairs
          token_pairs
            |> list.any(
                fn(token_pair) -> Bool {
                  let Pair(asset_name, _) = token_pair
                  or {
                    is_reference_asset_name(asset_name),
                    is_virtual_subhandle_asset_name(asset_name),
                  }
                },
              )
        },
      )
}

// - `ref_output` must have same address, value as `pz_utxo`
// - `ref_output` must NOT have reference_script
// - `ref_output` datum must be in CIP68Datum format.
//
pub fn check_ref_output(ref_output: Output, pz_utxo: Output) -> CIP68Datum {
  let Output {
    address: ref_output_address,
    value: ref_output_value,
    datum: new_datum,
    ..
  } = ref_output
  let Output { address: pz_utxo_address, value: pz_utxo_value, .. } = pz_utxo

  let address_is_same = ref_output_address == pz_utxo_address
  let value_is_same =
    value.without_lovelace(ref_output_value) == value.without_lovelace(
      pz_utxo_value,
    )
  expect address_is_same
  expect value_is_same

  expect InlineDatum(new_datum) = new_datum
  expect cip68_datum: CIP68Datum = new_datum

  cip68_datum
}

// - retrieve relevants outputs using pz_indexes
//   ref_output must be not None
pub fn parse_pz_indexes(
  outputs: List<Output>,
  pz_indexes: PzIndexes,
) -> (Output, Option<Output>, Option<Output>) {
  let PzIndexes { ref_output_index, user_output_index, treasury_output_index } =
    pz_indexes

  let ref_output_opt = list.at(outputs, ref_output_index)
  expect Some(ref_output) = ref_output_opt

  let user_output_opt = list.at(outputs, user_output_index)
  let treasury_output_opt = list.at(outputs, treasury_output_index)

  (ref_output, user_output_opt, treasury_output_opt)
}

pub fn parse_pz_asset_name(asset_name: AssetName) -> Handle {
  let prefix = bytearray.take(asset_name, 4)
  let handle_name = bytearray.drop(asset_name, 4)
  let (root_handle_name, is_subhandle, subhandle_name) =
    parse_handle_name(handle_name)

  if prefix == prefix_100 {
    // NFTHandle or NFTSubhandle
    if is_subhandle {
      NFTSubhandle(handle_name, root_handle_name, subhandle_name)
    } else {
      NFTHandle(handle_name)
    }
  } else if prefix == prefix_000 {
    // VirtualSubhandle
    expect is_subhandle

    VirtualSubhandle(handle_name, root_handle_name, subhandle_name)
  } else {
    fail @"invalid asset name label for pz asset"
  }
}

// - `new_metadata` must have `image` and `mediaType` (as single value)
// - for all keys in `old_metadata` other than `image` and `mediaType`,
//   there must be a corresponding key in `new_metadata` with same value.
//
pub fn check_new_metadata(
  new_metadata: Pairs<Data, Data>,
  old_metadata: Pairs<Data, Data>,
) -> (ByteArray, ByteArray) {
  let new_image_values = pairs.get_all(new_metadata, b_data("image"))
  let new_media_type_values = pairs.get_all(new_metadata, b_data("mediaType"))

  expect [new_image_data] = new_image_values
  expect new_image: ByteArray = new_image_data
  expect [new_media_type_data] = new_media_type_values
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

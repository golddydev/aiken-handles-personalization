use aiken/bytearray
use aiken/dict
use aiken/list
use aiken/transaction.{InlineDatum, Input, Output}
use aiken/transaction/value.{AssetName, PolicyId, Value}
use common/assets.{AssetClass}
use common/cip68.{
  CIP68Datum, check_asset_name_is_reference_asset_name,
  check_asset_name_is_virtual_subhandle_asset_name, prefix_000, prefix_100,
}
use handles/types.{Handle,
  NFTHandle, NFTSubhandle, VirtualSubhandle} as handles_types
use handles/utils.{parse_handle_name}

// - Finds the personalizing UTxO `pz_utxo`
//   UTxO with Reference Handle or Virtual Subhandle Asset.
//   Handle Assets can have several policy ids.
// - `pz_utxo` must be the only UTxO in inputs with referrence handle or Virtual Subhandle asset.
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
            check_value_has_reference_handle_asset_or_virtual_subhandle_asset(
              utxo_value,
              policy_ids,
            )
          },
        )

  // `pz_utxo` must be the only UTxO in inputs with referrence handle or Virtual Subhandle asset.
  expect [pz_input] = pz_inputs
  let Input { output: pz_output, .. } = pz_input
  let Output { value: pz_utxo_value, datum, .. } = pz_output

  // `pz_utxo` must have only one Asset of the given `asset_class` from redeemer.
  let (policy_id, asset_name) = asset_class
  let has_only_one_asset =
    value.without_lovelace(pz_utxo_value) == (
      value.zero()
        |> value.add(policy_id, asset_name, 1)
    )
  expect has_only_one_asset

  // `pz_utxo` datum must be in CIP68Datum format.
  expect InlineDatum(datum) = datum
  expect cip68_datum: CIP68Datum = datum

  (pz_output, cip68_datum)
}

fn check_value_has_reference_handle_asset_or_virtual_subhandle_asset(
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
                    check_asset_name_is_reference_asset_name(asset_name),
                    check_asset_name_is_virtual_subhandle_asset_name(asset_name),
                  }
                },
              )
        },
      )
}

// - `pz_output` must have same address, value as `pz_utxo`
// - `pz_output` must NOT have reference_script
// - `pz_output` datum must be in CIP68Datum format.
//
pub fn check_pz_output(pz_output: Output, pz_utxo: Output) -> CIP68Datum {
  let Output {
    address: pz_output_address,
    value: pz_output_value,
    datum: new_datum,
    ..
  } = pz_output
  let Output { address: pz_utxo_address, value: pz_utxo_value, .. } = pz_utxo

  let address_stay_same = pz_output_address == pz_utxo_address
  let value_stay_same =
    value.without_lovelace(pz_output_value) == value.without_lovelace(
      pz_utxo_value,
    )
  expect address_stay_same
  expect value_stay_same

  expect InlineDatum(new_datum) = new_datum
  expect cip68_datum: CIP68Datum = new_datum

  cip68_datum
}

// This function
// parse ref Handle OR Virtual Subhandle's asset_name as Handle
// 
// Returns: Handle and handle_name
//
pub fn parse_pz_asset_name(asset_name: AssetName) -> (Handle, ByteArray) {
  let prefix = bytearray.take(asset_name, 4)
  let handle_name = bytearray.drop(asset_name, 4)
  let (root_handle_name, is_subhandle, subhandle_name) =
    parse_handle_name(handle_name)

  if prefix == prefix_100 {
    // NFTHandle or NFTSubhandle
    if is_subhandle {
      (NFTSubhandle(handle_name, root_handle_name, subhandle_name), handle_name)
    } else {
      (NFTHandle(handle_name), handle_name)
    }
  } else if prefix == prefix_000 {
    // VirtualSubhandle
    expect is_subhandle

    (
      VirtualSubhandle(handle_name, root_handle_name, subhandle_name),
      handle_name,
    )
  } else {
    fail @"invalid asset name label for pz asset"
  }
}

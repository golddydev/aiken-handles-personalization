use aiken/dict
use aiken/list
use aiken/transaction.{InlineDatum, Input, Output}
use aiken/transaction/value.{PolicyId, Value}
use common/assets.{AssetClass}
use common/cip68.{
  CIP68Datum, is_reference_asset_name, is_virtual_subhandle_asset_name,
}

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

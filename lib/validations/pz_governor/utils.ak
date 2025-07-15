use aiken/dict
use aiken/list
use aiken/transaction.{Input, Output}
use aiken/transaction/value.{PolicyId, Value}
use common/cip68.{is_reference_asset_name, is_virtual_subhandle_asset_name}

// This function finds the personalizing UTxO
// UTxO with Reference Handle or Virtual Subhandle Asset
// Handle Assets can have several policy ids.
//
pub fn find_pz_utxo(inputs: List<Input>, policy_ids: List<PolicyId>) -> Output {
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

  // must have only one UTxO with Reference Handle or Virtual Subhandle Asset
  expect [pz_input] = pz_inputs
  pz_input.output
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

use aiken/list
use aiken/transaction.{InlineDatum, Input, Output}
use aiken/transaction/credential.{Address, ScriptCredential}
use aiken/transaction/value
use common/hashes.{ScriptHash}
use pz_items/types.{PzItems, pz_items_asset_name, pz_items_asset_policy_id}

/// Find PzItems from reference inputs.
/// input's output value must have `pz_items_asset`.
/// input's output address must be `settings_script_hash`.
///
pub fn find_pz_approved_policies(
  reference_inputs: List<Input>,
  settings_script_hash: ScriptHash,
) -> PzItems {
  let pz_approvers_input_opt =
    list.find(
      reference_inputs,
      fn(i) {
        value.quantity_of(
          i.output.value,
          pz_items_asset_policy_id,
          pz_items_asset_name,
        ) == 1
      },
    )
  expect Some(pz_approvers_input) = pz_approvers_input_opt

  let Input {
    output: Output { address: Address { payment_credential, .. }, datum, .. },
    ..
  } = pz_approvers_input

  let from_settings_script_hash =
    payment_credential == ScriptCredential(settings_script_hash)
  expect from_settings_script_hash

  // parse PzItems as InlineDatum
  expect InlineDatum(inline_datum) = datum
  expect pz_items: PzItems = inline_datum
  pz_items
}

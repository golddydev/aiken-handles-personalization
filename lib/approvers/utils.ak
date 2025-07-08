use aiken/list
use aiken/transaction.{InlineDatum, Input, Output}
use aiken/transaction/credential.{Address, ScriptCredential}
use approvers/types.{
  PZApproversData, pz_approvers_asset_name, pz_approvers_asset_policy_id,
}
use common/hashes.{ScriptHash}

/// Find PzApproversData from reference inputs.
/// input's output value must have pz_approvers_asset.
/// input's output address must be `settings_script_hash`.
///
pub fn find_pz_approvers_data(
  reference_inputs: List<Input>,
  settings_script_hash: ScriptHash,
) -> PZApproversData {
  let pz_approvers_input_opt =
    list.find(
      reference_inputs,
      fn(i) {
        value.quantity_of(
          i.output.value,
          pz_approvers_asset_policy_id,
          pz_approvers_asset_name,
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

  // parse PZApproversData as InlineDatum
  expect InlineDatum(inline_datum) = datum
  expect pz_approvers_data: PZApproversData = inline_datum
  pz_approvers_data
}

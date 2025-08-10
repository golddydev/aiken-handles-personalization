use aiken/bytearray
use aiken/list
use aiken/transaction.{InlineDatum, Input, Output}
use aiken/transaction/value.{PolicyId}
use common/cip68.{prefix_001}
use subhandle/types.{OwnerSettings}

// This function finds Owner Settings from reference inputs.
//
// NOTE:
// root_handle_name is without asset name label.
//
pub fn find_owner_settings(
  policy_ids: List<PolicyId>,
  reference_inputs: List<Input>,
  root_handle_name: ByteArray,
) -> OwnerSettings {
  let owner_asset_name = bytearray.concat(prefix_001, root_handle_name)
  let owner_settings_input_opt =
    list.find(
      reference_inputs,
      fn(i) {
        list.any(
          policy_ids,
          fn(policy_id) -> Bool {
            value.quantity_of(i.output.value, policy_id, owner_asset_name) == 1
          },
        )
      },
    )
  expect Some(owner_settings_input) = owner_settings_input_opt

  let Input { output: Output { datum, .. }, .. } = owner_settings_input

  // parse OwnerSettings as InlineDatum
  expect InlineDatum(inline_datum) = datum
  expect owner_settings: OwnerSettings = inline_datum

  owner_settings
}

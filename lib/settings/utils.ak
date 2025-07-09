use aiken/list
use aiken/transaction.{InlineDatum, Input, Output}
use aiken/transaction/value
use settings/types.{
  PzSettings, pz_settings_asset_name, pz_settings_asset_policy_id,
}

/// Find PzSettings from reference inputs.
/// input's output value must have `pz_settings_asset`.
///
pub fn find_pz_settings(reference_inputs: List<Input>) -> PzSettings {
  let pz_settings_input_opt =
    list.find(
      reference_inputs,
      fn(i) {
        value.quantity_of(
          i.output.value,
          pz_settings_asset_policy_id,
          pz_settings_asset_name,
        ) == 1
      },
    )
  expect Some(pz_settings_input) = pz_settings_input_opt

  let Input { output: Output { datum, .. }, .. } = pz_settings_input

  // parse PzSettings as InlineDatum
  expect InlineDatum(inline_datum) = datum
  expect pz_settings: PzSettings = inline_datum
  pz_settings
}

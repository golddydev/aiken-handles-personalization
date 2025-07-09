use aiken/list
use aiken/transaction.{InlineDatum, Input, Output}
use aiken/transaction/value.{AssetName, PolicyId}
use common/hashes.{ScriptHash}

const pz_settings_asset_policy_id: PolicyId =
  #"f0ff48bbb7bbe9d59a40f1ce90e9e9d0ff5002ec48f232b49ca0fb9a"

/// 222 "pz_settings"
const pz_settings_asset_name: AssetName = #"000de140707a5f73657474696e6773"

/// This is main settings of Personalization Contract
/// `data` will hold PzSettingsV1 Data
///
pub type PzSettings {
  pz_governor: ScriptHash,
  data: Data,
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

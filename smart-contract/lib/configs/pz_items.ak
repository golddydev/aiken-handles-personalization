use aiken/list
use aiken/transaction.{InlineDatum, Input, Output}
use aiken/transaction/value.{AssetName, PolicyId}

pub const pz_items_asset_policy_id: PolicyId =
  #"f0ff48bbb7bbe9d59a40f1ce90e9e9d0ff5002ec48f232b49ca0fb9a"

// 222 "pz_items"
pub const pz_items_asset_name: AssetName = #"000de140707a5f706f6c6963696573"

pub type PzItems {
  // MPT of approved policy ids for background and pfp
  policies: ByteArray,
  // MPT of beta assets ids (for nsfw and trial)
  beta_assets: ByteArray,
}

/// Find PzItems from reference inputs.
/// input's output value must have `pz_items_asset`.
///
pub fn find_pz_items(reference_inputs: List<Input>) -> PzItems {
  let pz_items_input_opt =
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
  expect Some(pz_items_input) = pz_items_input_opt
  let Input { output: Output { datum, .. }, .. } = pz_items_input

  // parse PzItems as InlineDatum
  expect InlineDatum(inline_datum) = datum
  expect pz_items: PzItems = inline_datum
  pz_items
}

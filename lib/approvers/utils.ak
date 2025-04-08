use aiken/list
use aiken/option
use aiken/pairs
use aiken/transaction.{InlineDatum, Input, Output}
use aiken/transaction/credential.{
  Address, Credential, ScriptCredential, VerificationKeyCredential,
}
use aiken/transaction/value.{AssetName}
use approvers/types.{PZApproverData}

// get approver information from reference inputs
// returns approver policy ids MPT root hash
// ByteArray
//
pub fn get_approver_information(
  reference_inputs: List<Input>,
  pz_providers: Pairs<ByteArray, ByteArray>,
  settings_cred: ByteArray,
  approver_index: Int,
  approver_policy_id: ByteArray,
  approver_asset_name: AssetName,
) -> ByteArray {
  expect Some(approver_input) = reference_inputs |> list.at(approver_index)
  let Input {
    output: Output {
      address: Address { payment_credential, .. },
      value: output_value,
      datum,
      ..
    },
    ..
  } = approver_input

  // check approver's address credential
  // if approver is settings credential
  // or one of pz providers
  let is_settings_cred = payment_credential == ScriptCredential(settings_cred)
  expect or {
      is_settings_cred,
      is_approver_pz_provider(payment_credential, pz_providers),
    }

  // check approver's input value has approver asset handle
  // "bg_policy_ids" or "pfp_policy_ids"
  let has_approver_asset =
    value.quantity_of(output_value, approver_policy_id, approver_asset_name) == 1
  expect has_approver_asset

  // parse approver input datum
  expect InlineDatum(inline_datum) = datum
  expect approver_data: PZApproverData = inline_datum
  let PZApproverData { mpt_root_hash } = approver_data
  mpt_root_hash
}

fn is_approver_pz_provider(
  approver_payment_credential: Credential,
  pz_providers: Pairs<ByteArray, ByteArray>,
) -> Bool {
  let approver_payment_credential_hash =
    when approver_payment_credential is {
      VerificationKeyCredential(verification_key_hash) -> verification_key_hash
      ScriptCredential(script_hash) -> script_hash
    }

  // search through pz providers values
  // because it is not signers
  //
  pz_providers
    |> pairs.find_first(approver_payment_credential_hash)
    |> option.and_then(fn(_) { Some(True) })
    |> option.or_else(False)
}

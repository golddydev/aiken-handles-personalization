use aiken/builtin.{b_data}
use aiken/list
use aiken/option
use aiken/pairs
use aiken/transaction.{InlineDatum, Input, Output}
use aiken/transaction/credential.{
  Address, Credential, ScriptCredential, VerificationKeyCredential,
}
use aiken/transaction/value.{AssetName}
use personalization/configs.{legacy_policy_id, pz_settings_asset_name}
use personalization/types.{HandleDatum, PZApproverData, PZSettings}

// find reference handle output
// this output is to one of valid_contracts
// and must be only one in transaction
//
pub fn find_reference_handle_output(
  outputs: List<Output>,
  valid_contracts: List<ByteArray>,
) -> Output {
  when
    outputs
      |> list.filter(
          fn(output) {
            let Output { address: Address { payment_credential, .. }, .. } =
              output
            valid_contracts
              |> list.any(
                  fn(valid_contract) -> Bool {
                    payment_credential == ScriptCredential(valid_contract)
                  },
                )
          },
        )
  is {
    [reference_handle_output] -> reference_handle_output
    _ -> fail @"must have only one reference handle output"
  }
}

pub fn get_handle_datum(reference_handle_output: Output) -> HandleDatum {
  expect InlineDatum(inline_datum) = reference_handle_output.datum
  expect handle_data: HandleDatum = inline_datum
  handle_data
}

// get handle extra informaion
// bg_asset and pfp_asset
// (Option<bg_image>, Option<pfp_image>, Option<bg_asset>, Option<pfp_asset>)
//
pub fn get_handle_extra_information(
  extra: Data,
) -> (
  Option<ByteArray>,
  Option<ByteArray>,
  Option<ByteArray>,
  Option<ByteArray>,
  Option<ByteArray>,
) {
  expect extra_pairs_data: Pairs<Data, Data> = extra
  do_get_handle_extra_information(
    (None, None, None, None, None),
    extra_pairs_data,
  )
}

fn do_get_handle_extra_information(
  result: (
    Option<ByteArray>,
    Option<ByteArray>,
    Option<ByteArray>,
    Option<ByteArray>,
    Option<ByteArray>,
  ),
  extra: Pairs<Data, Data>,
) -> (
  Option<ByteArray>,
  Option<ByteArray>,
  Option<ByteArray>,
  Option<ByteArray>,
  Option<ByteArray>,
) {
  when result is {
    (Some(_), Some(_), Some(_), Some(_), Some(_)) -> result
    _ ->
      when extra is {
        [] -> result
        [Pair(key, value), ..rest] -> {
          let (
            bg_image_opt,
            pfp_image_opt,
            bg_asset_opt,
            pfp_asset_opt,
            validated_by_opt,
          ) = result
          if bg_image_opt == None && key == b_data("bg_image") {
            expect bg_image: ByteArray = value
            do_get_handle_extra_information(
              (
                Some(bg_image),
                pfp_image_opt,
                bg_asset_opt,
                pfp_asset_opt,
                validated_by_opt,
              ),
              rest,
            )
          } else if pfp_image_opt == None && key == b_data("pfp_image") {
            expect pfp_image: ByteArray = value
            do_get_handle_extra_information(
              (
                bg_image_opt,
                Some(pfp_image),
                bg_asset_opt,
                pfp_asset_opt,
                validated_by_opt,
              ),
              rest,
            )
          } else if bg_asset_opt == None && key == b_data("bg_asset") {
            expect bg_asset: ByteArray = value
            do_get_handle_extra_information(
              (
                bg_image_opt,
                pfp_image_opt,
                Some(bg_asset),
                pfp_asset_opt,
                validated_by_opt,
              ),
              rest,
            )
          } else if pfp_asset_opt == None && key == b_data("pfp_asset") {
            expect pfp_asset: ByteArray = value
            do_get_handle_extra_information(
              (
                bg_image_opt,
                pfp_image_opt,
                bg_asset_opt,
                Some(pfp_asset),
                validated_by_opt,
              ),
              rest,
            )
          } else if validated_by_opt == None && key == b_data("validated_by") {
            expect validated_by: ByteArray = value
            do_get_handle_extra_information(
              (
                bg_image_opt,
                pfp_image_opt,
                bg_asset_opt,
                pfp_asset_opt,
                Some(validated_by),
              ),
              rest,
            )
          } else {
            do_get_handle_extra_information(result, rest)
          }
        }
      }
  }
}

// get pz settings information from reference inputs
// (pz_providers, valid_contracts, settings_cred)
// (Pairs<ByteArray, ByteArray>,List<ByteArray>,  ByteArray)
//
pub fn get_pz_settings_information(
  refernece_inputs: List<Input>,
  pz_settings_index: Int,
) -> (Pairs<ByteArray, ByteArray>, List<ByteArray>, ByteArray) {
  expect Some(pz_settings_input) =
    refernece_inputs |> list.at(pz_settings_index)
  let Input { output: Output { value: output_value, .. }, .. } =
    pz_settings_input

  // check if output contains PZ settings asset
  expect
    value.quantity_of(output_value, legacy_policy_id, pz_settings_asset_name) == 1

  expect InlineDatum(inline_datum) = pz_settings_input.output.datum
  expect pz_settings: PZSettings = inline_datum

  (pz_settings.4th, pz_settings.5th, pz_settings.7th)
}

// get approver information from reference inputs
// returns approver policy ids MPT root hash
// ByteArray
//
pub fn get_approver_information(
  reference_inputs: List<Input>,
  pz_providers: Pairs<ByteArray, ByteArray>,
  settings_cred: ByteArray,
  approver_index: Int,
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
    value.quantity_of(output_value, legacy_policy_id, approver_asset_name) == 1
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

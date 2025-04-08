use aiken/builtin.{b_data}
use aiken/list
use aiken/pairs.{get_first}
use aiken/transaction.{InlineDatum, Input, Output}
use aiken/transaction/credential.{Address, ScriptCredential}
use aiken/transaction/value.{AssetName, PolicyId}
use common/cip68.{make_reference_asset_name_from_user_asset_name}
use personalization/configs.{legacy_policy_id, pz_settings_asset_name}
use personalization/types.{CIP68Datum, PZSettings}

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

pub fn get_handle_datum(reference_handle_output: Output) -> CIP68Datum {
  expect InlineDatum(inline_datum) = reference_handle_output.datum
  expect handle_data: CIP68Datum = inline_datum
  handle_data
}

// get handle extra informaion
// bg_asset and pfp_asset
// (Option<bg_image>, Option<pfp_image>, Option<bg_asset>, 
// Option<pfp_asset>, Option<validated_by>, Option<trial>, Option<nsfw>)
//
pub fn get_handle_extra_information(
  extra: Data,
) -> (
  Option<ByteArray>,
  Option<ByteArray>,
  Option<ByteArray>,
  Option<ByteArray>,
  Option<ByteArray>,
  Option<Int>,
  Option<Int>,
) {
  expect extra_pairs_data: Pairs<Data, Data> = extra
  do_get_handle_extra_information(
    (None, None, None, None, None, None, None),
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
    Option<Int>,
    Option<Int>,
  ),
  extra: Pairs<Data, Data>,
) -> (
  Option<ByteArray>,
  Option<ByteArray>,
  Option<ByteArray>,
  Option<ByteArray>,
  Option<ByteArray>,
  Option<Int>,
  Option<Int>,
) {
  when result is {
    (Some(_), Some(_), Some(_), Some(_), Some(_), Some(_), Some(_)) -> result
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
            trial_opt,
            nsfw_opt,
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
                trial_opt,
                nsfw_opt,
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
                trial_opt,
                nsfw_opt,
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
                trial_opt,
                nsfw_opt,
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
                trial_opt,
                nsfw_opt,
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
                trial_opt,
                nsfw_opt,
              ),
              rest,
            )
          } else if trial_opt == None && key == b_data("trial") {
            expect trial: Int = value
            do_get_handle_extra_information(
              (
                bg_image_opt,
                pfp_image_opt,
                bg_asset_opt,
                pfp_asset_opt,
                validated_by_opt,
                Some(trial),
                nsfw_opt,
              ),
              rest,
            )
          } else if nsfw_opt == None && key == b_data("nsfw") {
            expect nsfw: Int = value
            do_get_handle_extra_information(
              (
                bg_image_opt,
                pfp_image_opt,
                bg_asset_opt,
                pfp_asset_opt,
                validated_by_opt,
                trial_opt,
                Some(nsfw),
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

pub fn get_pz_asset_image(
  pz_asset_policy_id: PolicyId,
  pz_asset_name: AssetName,
  pz_datum_index: Int,
  refernece_inputs: List<Input>,
) -> ByteArray {
  // check asset name is user asset name
  // and make reference asset name
  let reference_asset_name =
    make_reference_asset_name_from_user_asset_name(pz_asset_name)

  // find reference input
  expect Some(pz_asset_input) = refernece_inputs |> list.at(pz_datum_index)
  let Input {
    output: Output { value: output_value, datum: output_datum, .. },
    ..
  } = pz_asset_input

  // check value has reference asset
  let has_reference_asset =
    value.quantity_of(output_value, pz_asset_policy_id, reference_asset_name) == 1
  expect has_reference_asset

  // parse datum
  // and get image from pairs
  expect InlineDatum(inline_datum) = output_datum
  expect pz_asset_datum: CIP68Datum = inline_datum
  expect Some(pz_image_data) = get_first(pz_asset_datum.nft, b_data("image"))
  expect pz_image: ByteArray = pz_image_data

  pz_image
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

pub fn make_pz_asset_name_proof_value(pz_flags: (Int, Int)) -> ByteArray {
  when pz_flags is {
    (0, 0) -> #[0, 0]
    (0, 1) -> #[0, 1]
    (1, 0) -> #[1, 0]
    (1, 1) -> #[1, 1]
    _ -> fail @"pz flags must be (0, 0), (0, 1) or (1, 0) or (1, 1)"
  }
}

pub fn does_pz_flags_match_with_datum(
  bg_flags: (Int, Int),
  pfp_flags: (Int, Int),
  trial_opt: Option<Int>,
  nsfw_opt: Option<Int>,
) -> Bool {
  let trial =
    if bg_flags.1st + pfp_flags.1st > 0 {
      1
    } else {
      0
    }
  let nsfw =
    if bg_flags.2nd + pfp_flags.2nd > 0 {
      1
    } else {
      0
    }
  let is_trial_valid =
    when trial is {
      1 -> trial_opt == Some(1)
      0 -> trial_opt == Some(0) || trial_opt == None
      _ -> fail @"invalid trial value"
    }
  let is_nsfw_valid =
    when nsfw is {
      1 -> nsfw_opt == Some(1)
      0 -> nsfw_opt == Some(0) || nsfw_opt == None
      _ -> fail @"invalid nsfw value"
    }
  and {
    is_trial_valid,
    is_nsfw_valid,
  }
}

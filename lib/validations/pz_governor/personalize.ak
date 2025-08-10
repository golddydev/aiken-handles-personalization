use aiken/builtin.{b_data}
use aiken/cbor
use aiken/list
use aiken/pairs
use aiken/string
use aiken/transaction.{Output}
use common/collections.{
  get_first_int_value_from_pairs, get_single_bytearray_value_from_pairs,
  get_single_int_value_from_pairs, get_single_value_from_pairs,
}
use common/hashes.{VerificationKeyHash}
use configs/settings_v1.{PzSettingsV1}
use handles/constants.{agreed_terms_url}
use handles/types.{Handle} as handles_types
use validations/pz_governor/types.{PzIndexes}

// This function parses outputs using `pz_indexes`
// - first output must be `pz_output` (ref_output)
// - second output must be `user_output`
// - retrieve relevant outputs using pz_indexes
//
pub fn parse_outputs(
  outputs: List<Output>,
  pz_indexes: PzIndexes,
) -> (Output, Output, Option<Output>, Option<Output>, Option<Output>) {
  expect [pz_output, user_output, ..] = outputs

  let PzIndexes {
    treasury_output_index,
    provider_fee_output_index,
    shared_fee_output_index,
  } = pz_indexes

  let treasury_output_opt = list.at(outputs, treasury_output_index)
  let provider_fee_output_opt = list.at(outputs, provider_fee_output_index)
  let shared_fee_output_opt = list.at(outputs, shared_fee_output_index)

  (
    pz_output,
    user_output,
    treasury_output_opt,
    provider_fee_output_opt,
    shared_fee_output_opt,
  )
}

// - `new_metadata` must have `image` and `mediaType` (as single value)
// - for all keys in `old_metadata` other than `image` and `mediaType`,
//   there must be a corresponding key in `new_metadata` with same value.
//
// returns: (new_image, new_media_type)
//
pub fn check_new_metadata(
  new_metadata: Pairs<Data, Data>,
  old_metadata: Pairs<Data, Data>,
) -> (ByteArray, ByteArray) {
  // immutable values
  let new_image_opt =
    get_single_bytearray_value_from_pairs(new_metadata, "image")
  let new_media_type_opt =
    get_single_bytearray_value_from_pairs(new_metadata, "mediaType")
  expect Some(new_image) = new_image_opt
  expect Some(new_media_type) = new_media_type_opt

  let immutables_stay_same =
    old_metadata
      |> pairs.foldl(
          True,
          fn(key, value, acc) -> Bool {
            acc && if key == b_data("image") || key == b_data("mediaType") {
              True
            } else {
              let new_value_opt = pairs.get_first(new_metadata, key)
              let immutable_stay_same = new_value_opt == Some(value)
              if immutable_stay_same {
                True
              } else {
                trace string.concat(
                  @"immutable metadata changed: ",
                  cbor.diagnostic(key),
                )
                False
              }
            }
          },
        )
  expect immutables_stay_same

  (new_image, new_media_type)
}

// - transaction must be signed by `validated_by` if it is set as single value.
// - `standard_image`, `standard_image_hash`, `original_address` must be same as `old_extra`. (as single value or None)
// - `agreed_terms` must be same as `agreed_terms_url`.
// - `last_edited_time` must be same as transaction's start time.
//
// returns: Option<Int>
//
pub fn check_new_extra(
  new_extra: Pairs<Data, Data>,
  old_extra: Pairs<Data, Data>,
  extra_signatories: List<VerificationKeyHash>,
  transaction_start_time: Int,
) -> Option<Int> {
  // tansaction must be signed by `validated_by` if it is set as single value.
  let validated_by_opt =
    get_single_bytearray_value_from_pairs(new_extra, "validated_by")
  let is_tx_signed_by_validated_by =
    when validated_by_opt is {
      None -> True
      Some(validated_by) -> list.has(extra_signatories, validated_by)
    }
  expect is_tx_signed_by_validated_by

  // - `standard_image`, `standard_image_hash`, `original_address` must be same as `old_extra`. (as single value or None)
  let immutables_stay_same =
    ["standard_image", "standard_image_hash", "original_address"]
      |> list.all(
          fn(key) -> Bool {
            let new_value = get_single_value_from_pairs(new_extra, key)
            let old_value = get_single_value_from_pairs(old_extra, key)
            let immutable_stay_same = new_value == old_value

            if immutable_stay_same {
              True
            } else {
              trace string.concat(
                @"immutable extra changed: ",
                cbor.diagnostic(key),
              )
              False
            }
          },
        )
  expect immutables_stay_same

  // `agreed_terms` must be same as `"https://handle.me/$/tou"`.
  let agreed_terms_opt =
    get_single_bytearray_value_from_pairs(new_extra, "agreed_terms")
  expect Some(agreed_terms) = agreed_terms_opt
  let is_agreed_terms_valid = agreed_terms == agreed_terms_url
  expect is_agreed_terms_valid

  // `last_edited_time` must be same as transaction validity range's lower bound.
  let last_edited_time_opt =
    get_single_int_value_from_pairs(new_extra, "last_edited_time")
  expect Some(last_edited_time) = last_edited_time_opt
  let is_last_edited_time_valid = last_edited_time == transaction_start_time
  expect is_last_edited_time_valid

  // get `last_edited_time` from old datum's extra
  let old_last_edited_time_opt =
    get_first_int_value_from_pairs(old_extra, "last_edited_time")

  old_last_edited_time_opt
}

// This function checks
// corresponding fees are paid correctly
// returns: Bool
//
//
pub fn check_fees_are_paid(
  pz_handle: Handle,
  settings_v1: PzSettingsV1,
  treasury_output_opt: Option<Output>,
  provider_fee_output_opt: Option<Output>,
  shared_fee_output_opt: Option<Output>,
  last_edited_time_opt: Option<Int>,
  transaction_start_time: Int,
) -> Bool {
  let PzSettingsV1 { grace_period, .. } = settings_v1

  // check tx is in grace period
  let is_in_grace_period =
    when last_edited_time_opt is {
      Some(last_edited_time) ->
        transaction_start_time < last_edited_time + grace_period
      None -> False
    }
  if is_in_grace_period {
    trace @"in grace period"
    True
  } else {
    todo
  }
}

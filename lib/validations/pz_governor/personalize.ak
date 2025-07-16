use aiken/builtin.{b_data}
use aiken/cbor
use aiken/list
use aiken/pairs
use aiken/string
use aiken/transaction.{Output}
use handles/constants.{agreed_terms_url}
use validations/pz_governor/types.{PzIndexes}

// - retrieve relevants outputs using pz_indexes
//   ref_output must be not None
pub fn parse_pz_indexes(
  outputs: List<Output>,
  pz_indexes: PzIndexes,
) -> (Output, Option<Output>, Option<Output>) {
  let PzIndexes { ref_output_index, user_output_index, treasury_output_index } =
    pz_indexes

  let ref_output_opt = list.at(outputs, ref_output_index)
  expect Some(ref_output) = ref_output_opt

  let user_output_opt = list.at(outputs, user_output_index)
  let treasury_output_opt = list.at(outputs, treasury_output_index)

  (ref_output, user_output_opt, treasury_output_opt)
}

// - `new_metadata` must have `image` and `mediaType` (as single value)
// - for all keys in `old_metadata` other than `image` and `mediaType`,
//   there must be a corresponding key in `new_metadata` with same value.
//
pub fn check_new_metadata(
  new_metadata: Pairs<Data, Data>,
  old_metadata: Pairs<Data, Data>,
) -> (ByteArray, ByteArray) {
  let new_image_values = pairs.get_all(new_metadata, b_data("image"))
  let new_media_type_values = pairs.get_all(new_metadata, b_data("mediaType"))

  expect [new_image_data] = new_image_values
  expect new_image: ByteArray = new_image_data
  expect [new_media_type_data] = new_media_type_values
  expect new_media_type: ByteArray = new_media_type_data

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

// - both `new_extra` and `old_extra` must be in Pairs<Data, Data> format.
// - `standard_image`, `standard_image_hash`, `original_address` must be same as `old_extra`. (as single value or None)
// - `agreed_terms` must be same as `agreed_terms_url`.
// - `last_edited_time` must be same as transaction's start time.
//
pub fn check_new_extra(
  new_extra_data: Data,
  old_extra_data: Data,
  transaction_start_time: Int,
) -> Pairs<Data, Data> {
  expect new_extra: Pairs<Data, Data> = new_extra_data
  expect old_extra: Pairs<Data, Data> = old_extra_data

  // - `standard_image`, `standard_image_hash`, `original_address` must be same as `old_extra`. (as single value or None)
  let immutables_stay_same =
    ["standard_image", "standard_image_hash", "original_address"]
      |> list.all(
          fn(key) -> Bool {
            let new_values = pairs.get_all(new_extra, b_data(key))
            let old_values = pairs.get_all(old_extra, b_data(key))

            let immutable_stay_same_without_duplicates = and {
                new_values == old_values,
                list.length(new_values) <= 1,
              }

            if immutable_stay_same_without_duplicates {
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
  let agreed_terms_values = pairs.get_all(new_extra, b_data("agreed_terms"))
  expect [agreed_terms_data] = agreed_terms_values
  expect agreed_terms: ByteArray = agreed_terms_data
  let is_agreed_terms_valid = agreed_terms == agreed_terms_url
  expect is_agreed_terms_valid

  // `last_edited_time` must be same as transaction validity range's lower bound.
  let last_edited_time_values =
    pairs.get_all(new_extra, b_data("last_edited_time"))
  expect [last_edited_time_data] = last_edited_time_values
  expect last_edited_time: Int = last_edited_time_data
  let is_last_edited_time_valid = last_edited_time == transaction_start_time
  expect is_last_edited_time_valid

  new_extra
}

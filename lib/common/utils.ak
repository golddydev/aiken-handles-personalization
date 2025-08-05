use aiken/builtin
use aiken/bytearray
use aiken/interval.{Finite, IntervalBound}
use aiken/list
use aiken/pairs
use aiken/string
use aiken/transaction.{
  InlineDatum, Input, Output, OutputReference, ValidityRange, find_input,
}
use aiken/transaction/credential.{
  Address, Inline, ScriptCredential, StakeCredential,
}
use aiken/transaction/value
use common/assets.{parse_asset_id}
use common/cip68.{
  CIP68Datum, check_asset_name_is_user_asset_or_rft, get_reference_asset_name,
}
use common/collections.{get_single_value_from_pairs}
use common/hashes.{ScriptHash}

// This function checks if transaction starts
// after from finit time
pub fn check_transaction_is_valid_after_finite_time(
  validity_range: ValidityRange,
) -> Int {
  let IntervalBound { bound_type, .. } = validity_range.lower_bound
  when bound_type is {
    Finite(start_time) -> start_time
    _ -> fail @"invalid lower bound"
  }
}

// This function checks if withdrawal validator is executed.
//
pub fn is_withdrawal_script_executed(
  withdrawals: Pairs<StakeCredential, Int>,
  script_hash: ScriptHash,
) -> Bool {
  pairs.has_key(withdrawals, Inline(ScriptCredential(script_hash)))
}

// This function returns own spending UTxO
// when script context's purpose is Spending.
//
pub fn get_own_utxo(
  inputs: List<Input>,
  spending_output_reference: OutputReference,
) -> Output {
  expect Some(spending_input) = find_input(inputs, spending_output_reference)
  spending_input.output
}

// This function returns own UTxO's script hash.
//
pub fn get_own_script_hash(own_utxo: Output) -> ScriptHash {
  let Output { address: Address { payment_credential, .. }, .. } = own_utxo
  expect ScriptCredential(spending_script_hash) = payment_credential

  spending_script_hash
}

// This function returns the count of UTxO
// from own_script_hash.
//
pub fn get_own_utxos_count(
  inputs: List<Input>,
  own_script_hash: ScriptHash,
) -> Int {
  let own_utxo_count =
    inputs
      |> list.count(
          fn(input: Input) -> Bool {
            let Input {
              output: Output { address: Address { payment_credential, .. }, .. },
              ..
            } = input
            when payment_credential is {
              ScriptCredential(script_hash) -> script_hash == own_script_hash
              _ -> False
            }
          },
        )
  own_utxo_count
}

/// This function find datum by user asset id from reference inputs
/// Also do checks what asset name is either CIP-25 CIP-68
/// if asset name is CIP-68, that must be user token or RFT with valid CIP68Datum
/// if asset name is CIP-25, just return None
///
pub fn find_datum_by_user_asset_id(
  asset_id: ByteArray,
  reference_inputs: List<Input>,
) -> Option<CIP68Datum> {
  let (policy_id, asset_name) = parse_asset_id(asset_id)
  let (is_asset_name_user_asset_or_rft, is_cip68) =
    check_asset_name_is_user_asset_or_rft(asset_name)
  expect is_asset_name_user_asset_or_rft

  when is_cip68 is {
    True -> {
      let reference_asset_name = get_reference_asset_name(asset_name)
      let reference_asset_input_opt =
        reference_inputs
          |> list.find(
              fn(input: Input) -> Bool {
                let Input { output: Output { value: v, .. }, .. } = input
                let has_reference_asset =
                  value.quantity_of(v, policy_id, reference_asset_name) == 1
                has_reference_asset
              },
            )
      expect Some(reference_asset_input) = reference_asset_input_opt
      let Input { output: Output { datum, .. }, .. } = reference_asset_input
      expect InlineDatum(inline_datum) = datum
      expect cip68_datum: CIP68Datum = inline_datum

      Some(cip68_datum)
    }
    False -> None
  }
}

// this function checks
// - output has asset with asset_id
// returns: Bool
//
pub fn check_output_has_asset_by_asset_id(
  output: Output,
  asset_id: ByteArray,
  quantity: Int,
) -> Bool {
  let Output { value: v, .. } = output
  let (policy_id, asset_name) = parse_asset_id(asset_id)
  let has_asset = value.quantity_of(v, policy_id, asset_name) == quantity
  has_asset
}

// This function get `attributes` from CIP68Datum
// if `metadata` has `attributes` property, that must be Pairs<Data, Data>
// otherwise, just return `metadata`
//
pub fn get_attributes_from_datum(datum: CIP68Datum) -> Pairs<Data, Data> {
  let CIP68Datum { metadata, .. } = datum
  let attributes_value = get_single_value_from_pairs(metadata, "attributes")
  when attributes_value is {
    Some(attributes_data) -> {
      expect attributes: Pairs<Data, Data> = attributes_data
      attributes
    }
    None -> metadata
  }
}

// This function
// parse bytearray as attribute key_value (`"key:value"` in utf8 format)
//
pub fn parse_attribute_key_value(
  attribute_bytes: ByteArray,
) -> (ByteArray, ByteArray, String) {
  // just check attribute is in valid utf8 format
  let attribute_string = string.from_bytearray(attribute_bytes)

  when index_of_colon_symbol(attribute_bytes) is {
    Some(idx) -> {
      let key = bytearray.take(attribute_bytes, idx)
      let value = bytearray.drop(attribute_bytes, idx + 1)
      let is_key_valid = bytearray.length(key) > 0
      when is_key_valid is {
        True -> (key, value, attribute_string)
        False ->
          fail string.concat(
            @"required_attribute's key is invalid: ",
            attribute_string,
          )
      }
    }
    None ->
      fail string.concat(@"required_attribute is invalid: ", attribute_string)
  }
}

fn index_of_colon_symbol(attribute_bytes: ByteArray) -> Option<Int> {
  let length = bytearray.length(attribute_bytes)
  do_index_of_colon_symbol(attribute_bytes, 0, length)
}

fn do_index_of_colon_symbol(
  handle_name: ByteArray,
  idx: Int,
  length: Int,
) -> Option<Int> {
  if idx >= length {
    None
  } else {
    if builtin.index_bytearray(handle_name, idx) == 0x3a {
      Some(idx)
    } else {
      do_index_of_colon_symbol(handle_name, idx + 1, length)
    }
  }
}

pub fn convert_int_to_bool(value: Int) -> Bool {
  when value is {
    0 -> False
    _ -> True
  }
}

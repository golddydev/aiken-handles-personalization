use aiken/interval.{Finite, IntervalBound}
use aiken/list
use aiken/pairs
use aiken/transaction.{
  InlineDatum, Input, Output, OutputReference, ValidityRange, find_input,
}
use aiken/transaction/credential.{
  Address, Inline, ScriptCredential, StakeCredential,
}
use aiken/transaction/value
use common/assets.{AssetClass, parse_asset_id}
use common/cip68.{
  CIP68Datum, check_asset_name_is_user_asset_or_rft, get_reference_asset_name,
}
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

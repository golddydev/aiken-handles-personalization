use aiken/interval.{Finite, IntervalBound}
use aiken/list
use aiken/pairs
use aiken/transaction.{Input,
  Output, OutputReference, ValidityRange, find_input}
use aiken/transaction/credential.{
  Address, Inline, ScriptCredential, StakeCredential,
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

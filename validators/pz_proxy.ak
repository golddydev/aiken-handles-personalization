use aiken/transaction.{ScriptContext, Spend, Transaction}
use common/utils.{is_withdrawal_script_executed}
use configs/settings.{PzSettings, find_pz_settings}

/// NOTE:
/// 
/// This is a spending validator
/// where Handle Reference Tokens and Virtual Subhandle Tokens are locked
/// with CIP68Datum.
///
/// This script hash doesn't change without strong reason.
/// It only checks if the `pz_governor` withdrawal validator is executed.
///
/// When this script can change?
///
/// - `configs/settings.ak` is updated.
/// 
validator {
  fn spend(_datum: Data, _redeemer: Data, ctx: ScriptContext) -> Bool {
    let ScriptContext { transaction, purpose } = ctx

    // must be spending validator
    expect Spend(_) = purpose

    let Transaction { withdrawals, reference_inputs, .. } = transaction

    // find settings asset and parse it
    let PzSettings { pz_governor, .. } = find_pz_settings(reference_inputs)

    // check mint_governor is executed
    expect is_withdrawal_script_executed(withdrawals, pz_governor)

    True
  }
}

use aiken/transaction.{ScriptContext, WithdrawFrom}
use validations/pz_governor/validation.{can_personalize}

type PzGovernorRedeemer {
  Personalize
  Reset
  Migrate
  Revoke
}

/// NOTE:
///
/// This is a withdrawal validator which holds all personalization logic.
/// This is referred to as `pz_governor` in `PzSettings`.
///
validator {
  fn withdraw(redeemer: PzGovernorRedeemer, ctx: ScriptContext) -> Bool {
    let ScriptContext { purpose, transaction } = ctx

    // must be spending validator
    expect WithdrawFrom(_) = purpose

    when redeemer is {
      Personalize -> can_personalize(transaction)
      Reset -> False
      Migrate -> False
      Revoke -> False
    }
  }
}

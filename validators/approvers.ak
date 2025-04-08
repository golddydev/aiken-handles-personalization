use aiken/transaction.{ScriptContext, WithdrawFrom}
use personalization/types.{Redeemer}
use personalization/validation.{can_personalize_assets}

validator {
  fn withdraw(redeemer: Redeemer, ctx: ScriptContext) -> Bool {
    let ScriptContext { transaction, purpose } = ctx
    // must be withdrawal validator
    expect WithdrawFrom(_) = purpose

    let Redeemer { indexes, approver_proofs } = redeemer
    can_personalize_assets(transaction, indexes, approver_proofs)
  }
}

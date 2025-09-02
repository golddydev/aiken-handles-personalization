use aiken/transaction.{ScriptContext, WithdrawFrom}
use common/assets.{AssetClass}
use validations/bg_constraints/validation.{check_bg_constraints}

// asset class and designer settings
// - asset class: The asset being personalized
// - designer settings: Personalized designer settings
// 
type BgConstraintsRedeemer =
  (AssetClass, Pairs<ByteArray, Data>)

/// NOTE:
///
/// This is a withdrawal validator which checks bg asset's constraints.
/// This is referred to as `bg_constraints_governor` in `PzSettings`.
///
/// CAUTION:
/// This validator must be executed with `pz_governor` withdrawal script.
///
validator {
  fn withdraw(redeemer: BgConstraintsRedeemer, ctx: ScriptContext) -> Bool {
    let ScriptContext { purpose, transaction } = ctx
    let (asset_class, designer_settings) = redeemer

    // must be spending validator
    expect WithdrawFrom(_) = purpose

    let bg_constraints_met =
      check_bg_constraints(asset_class, transaction, designer_settings)
    expect bg_constraints_met

    True
  }
}

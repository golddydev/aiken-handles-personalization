use aiken/transaction.{ScriptContext, WithdrawFrom}
use validations/pz_assets/types.{PzAssetsProofs}
use validations/pz_assets/validation.{check_pz_assets}

/// NOTE:
///
/// This is a withdrawal validator which checks pz assets (bg_asset and pfp_asset)
/// Meaning that this validator will check
/// `bg_asset`, `bg_image`, `pfp_asset`, `pfp_image` are all correctly set.
/// `bg_asset`, `pfp_asset` are approved.
/// `pz_flags` are correctly set from `bg_asset` and `pfp_asset` flags.
/// This is referred to as `pz_assets_governor` in `PzSettings`.
///
/// CAUTION:
/// This validator must be executed with `pz_governor` withdrawal script.
///
validator {
  fn withdraw(pz_assets_proofs: PzAssetsProofs, ctx: ScriptContext) -> Bool {
    let ScriptContext { purpose, transaction } = ctx

    // must be spending validator
    expect WithdrawFrom(_) = purpose

    let pz_assets_valid = check_pz_assets(pz_assets_proofs, transaction)
    expect pz_assets_valid

    True
  }
}

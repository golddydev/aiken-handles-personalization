use aiken/transaction.{ScriptContext, WithdrawFrom}
use common/assets.{AssetClass}
use validations/pz_governor/types.{PzAssetsProofs, PzIndexes}
use validations/pz_governor/validation.{can_personalize}

type PzGovernorRedeemer {
  Personalize(AssetClass, PzIndexes, PzAssetsProofs, Pairs<Data, Data>)
  Reset
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
      Personalize(asset_class, pz_indexes, pz_assets_proofs, designer) ->
        can_personalize(
          transaction,
          asset_class,
          pz_indexes,
          pz_assets_proofs,
          designer,
        )
      Reset -> False
      Revoke -> False
    }
  }
}

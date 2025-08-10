use aiken/bytearray
use aiken/transaction.{Transaction}
use common/assets.{AssetClass}
use common/cip68.{CIP68Datum}
use common/collections.{get_single_bytearray_value_from_pairs}
use validations/bg_constraints/utils.{
  check_bg_constraints_are_met, check_pz_output_has_only_asset_class,
  get_bg_asset_datum,
}

// Validation:
// 
// CAUTION: This function assumes that `pz_governor` withdrawal script is executed
// and first output must be `pz_output`.
//
pub fn check_bg_constraints(
  asset_class: AssetClass,
  transaction: Transaction,
) -> Bool {
  let (policy_id, asset_name) = asset_class
  let Transaction { reference_inputs, outputs, extra_signatories, .. } =
    transaction

  // parse outputs
  expect [pz_output, user_output, ..] = outputs

  // check pz_output has only one asset with given asset_class
  let new_datum = check_pz_output_has_only_asset_class(pz_output, asset_class)

  // get bg asset's CIP68Datum
  let bg_datum_opt = get_bg_asset_datum(new_datum, reference_inputs)

  when bg_datum_opt is {
    None ->
      // if bg_datum is None, we don't need to check bg constraints
      True
    Some(bg_datum) -> {
      // get pfp_asset_id
      let CIP68Datum { extra: new_extra, .. } = new_datum
      expect new_extra: Pairs<Data, Data> = new_extra
      let pfp_asset_id_opt =
        get_single_bytearray_value_from_pairs(new_extra, "pfp_asset_id")

      // if bg_datum is not None, we need to check bg constraints
      let handle_name = bytearray.drop(asset_name, 4)

      let bg_constraints_met =
        check_bg_constraints_are_met(
          bg_datum,
          user_output,
          reference_inputs,
          extra_signatories,
          policy_id,
          handle_name,
          pfp_asset_id_opt,
        )
      expect bg_constraints_met
      True
    }
  }
}

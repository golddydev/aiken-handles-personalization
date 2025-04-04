use aiken/list
use aiken/transaction.{Transaction}
use personalization/configs.{bg_approver_asset_name, pfp_approver_asset_name}
use personalization/legacy.{
  find_reference_handle_output, get_handle_datum, get_handle_extra_information,
  get_pz_settings_information,
}
use personalization/types.{Indexes}

pub fn can_personalize_assets(
  transaction: Transaction,
  indexes: Indexes,
) -> Bool {
  let Transaction { inputs, outputs, reference_inputs, extra_signatories, .. } =
    transaction
  let Indexes {
    pz_settings_index,
    bg_approvers_index,
    pfp_approvers_index,
    bg_datum_index,
    pfp_datum_index,
  } = indexes

  // get pz_providers and settings_cred from pz settings
  let (pz_providers, valid_contracts, settings_cred) =
    get_pz_settings_information(reference_inputs, pz_settings_index)

  // find reference handle output
  // and parse handle datum
  let reference_handle_output =
    find_reference_handle_output(outputs, valid_contracts)
  let handle_datum = get_handle_datum(reference_handle_output)

  // get extra data information
  let (
    bg_image_opt,
    pfp_image_opt,
    bg_asset_opt,
    pfp_asset_opt,
    validated_by_opt,
  ) = get_handle_extra_information(handle_datum.extra)

  // check if the transaction is signed by the validated_by
  expect is_signed_by_validated_by(extra_signatories, validated_by_opt)

  // check if
  // get pz approvers mpt root hash
  todo
}

fn is_signed_by_validated_by(
  extra_signatories: List<ByteArray>,
  validated_by_opt: Option<ByteArray>,
) -> Bool {
  when validated_by_opt is {
    Some(validated_by) ->
      extra_signatories |> list.any(fn(signatory) { signatory == validated_by })
    _ -> True
  }
}

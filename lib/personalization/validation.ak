use aiken/list
use aiken/merkle_patricia_forestry as mpt
use aiken/transaction.{Input, Transaction}
use approvers/utils.{get_approver_information} as approver_utils
use common/utils.{not_has, parse_asset_bytearray} as common_utils
use personalization/configs.{
  bg_approver_asset_name, legacy_policy_id, pfp_approver_asset_name,
}
use personalization/types.{ApproverProofs, Indexes}
use personalization/utils.{
  does_pz_flags_match_with_datum, find_reference_handle_output, get_handle_datum,
  get_handle_extra_information, get_pz_asset_image, get_pz_settings_information,
  make_pz_asset_name_proof_value,
} as personalization_utils

pub fn can_personalize_assets(
  transaction: Transaction,
  indexes: Indexes,
  approver_proofs: ApproverProofs,
) -> Bool {
  let Transaction { outputs, reference_inputs, extra_signatories, .. } =
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
    trial_opt,
    nsfw_opt,
  ) = get_handle_extra_information(handle_datum.extra)

  // check if the transaction is signed by the validated_by
  expect is_signed_by_validated_by(extra_signatories, validated_by_opt)

  // parse proofs
  let ApproverProofs {
    bg_policy_id_proof_opt,
    bg_policy_id_proof_value,
    bg_flags,
    bg_asset_name_proof_opt,
    pfp_policy_id_proof_opt,
    pfp_policy_id_proof_value,
    pfp_flags,
    pfp_asset_name_proof_opt,
  } = approver_proofs

  // check if pz flags match with trial and nsfw in datum
  let does_pz_flags_match =
    does_pz_flags_match_with_datum(bg_flags, pfp_flags, trial_opt, nsfw_opt)
  expect does_pz_flags_match

  // check if bg asset and image is valid
  expect
    is_pz_image_and_asset_valid(
      bg_image_opt,
      bg_asset_opt,
      bg_policy_id_proof_opt,
      bg_policy_id_proof_value,
      bg_flags,
      bg_asset_name_proof_opt,
      bg_datum_index,
      reference_inputs,
      fn() {
        get_approver_information(
          reference_inputs,
          pz_providers,
          settings_cred,
          bg_approvers_index,
          legacy_policy_id,
          bg_approver_asset_name,
        )
      },
    )

  // check if pfp asset and image is valid
  expect
    is_pz_image_and_asset_valid(
      pfp_image_opt,
      pfp_asset_opt,
      pfp_policy_id_proof_opt,
      pfp_policy_id_proof_value,
      pfp_flags,
      pfp_asset_name_proof_opt,
      pfp_datum_index,
      reference_inputs,
      fn() {
        get_approver_information(
          reference_inputs,
          pz_providers,
          settings_cred,
          pfp_approvers_index,
          legacy_policy_id,
          pfp_approver_asset_name,
        )
      },
    )

  True
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

// check pz image and asset is valid
// and pz_flags are correct with proof
// pz_policy_id_proof_opt: Proof for policy id membership
// pz_policy_id_proof_value: Value of policy id in the MPT
// either "" or root hash of MPT of asset names 
// pz_flags: Flags for trial | nsfw
// pz_asset_name_proof_opt: Proof for asset name membership or non-membership
//
fn is_pz_image_and_asset_valid(
  pz_image_opt: Option<ByteArray>,
  pz_asset_opt: Option<ByteArray>,
  pz_policy_id_proof_opt: Option<mpt.Proof>,
  pz_policy_id_proof_value: ByteArray,
  pz_flags: (Int, Int),
  pz_asset_name_proof_opt: Option<mpt.Proof>,
  pz_asset_datum_index: Int,
  reference_inputs: List<Input>,
  get_approver_information_function: fn() -> ByteArray,
) -> Bool {
  when (pz_image_opt, pz_asset_opt) is {
    // when both are None return True
    (None, None) -> True
    // when bot are set, do the check
    (Some(pz_image), Some(pz_asset)) -> {
      // parse asset bytearray
      let (pz_asset_policy_id, pz_asset_name) = parse_asset_bytearray(pz_asset)

      // check pz_image is same as image in datum
      let pz_asset_image_in_datum =
        get_pz_asset_image(
          pz_asset_policy_id,
          pz_asset_name,
          pz_asset_datum_index,
          reference_inputs,
        )
      expect pz_image == pz_asset_image_in_datum

      // unwrap policy_id proof
      expect Some(pz_policy_id_proof) = pz_policy_id_proof_opt

      // make merkle trie from root hash
      let approver_mpt_root_hash = get_approver_information_function()
      let root = mpt.from_root(approver_mpt_root_hash)

      // check pz asset policy id is in root
      let is_pz_asset_policy_id_in_root =
        mpt.has(
          root,
          pz_asset_policy_id,
          pz_policy_id_proof_value,
          pz_policy_id_proof,
        )
      expect is_pz_asset_policy_id_in_root

      // check flags is valid with proof
      let is_flags_valid =
        is_pz_flags_valid(
          pz_policy_id_proof_value,
          pz_asset_name,
          pz_flags,
          pz_asset_name_proof_opt,
        )
      expect is_flags_valid
      //
      True
    }
    // otherwise
    _ -> {
      trace @"pz_image and pz_asset mismatch"
      False
    }
  }
}

// Check provided flags are valid with proof
// pz_asset_names_mpt_root_hash: Root hash of the MPT of asset names
// when empty string, means there is no MPT for asset names
// pz_flags: Flags for trial | nsfw
// pz_asset_name_proof_opt: Proof for the asset name
//
fn is_pz_flags_valid(
  pz_asset_names_mpt_root_hash: ByteArray,
  pz_asset_name: ByteArray,
  pz_flags: (Int, Int),
  pz_asset_name_proof_opt: Option<mpt.Proof>,
) -> Bool {
  if pz_asset_names_mpt_root_hash == #"" {
    // when there is no MPT for asset names
    // the pz_flags must be (0, 0) -  not trial, not nsfw
    expect pz_flags == (0, 0)
    True
  } else {
    // when there is MPT for asset names
    // then check the proof with pz_flags
    //
    // make merkle trie from root hash
    // unwrap proof
    let root = mpt.from_root(pz_asset_names_mpt_root_hash)
    expect Some(pz_asset_name_proof) = pz_asset_name_proof_opt
    //
    when pz_flags is {
      (0, 0) -> {
        // if asset name is not trial nor nsfw
        // then must proof non-membership of asset name in the MPT
        expect not_has(root, pz_asset_name, pz_asset_name_proof)
        True
      }
      _ -> {
        // make proof value
        // this also ensures that the flags are valid
        // (0, 1) or (1, 0) or (1, 1)
        let pz_asset_name_proof_value = make_pz_asset_name_proof_value(pz_flags)
        // then prove membership of asset name proof value in the MPT
        let is_pz_asset_name_proof_value_in_root =
          mpt.has(
            root,
            pz_asset_name,
            pz_asset_name_proof_value,
            pz_asset_name_proof,
          )
        expect is_pz_asset_name_proof_value_in_root
        True
      }
    }
  }
}

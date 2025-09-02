use aiken/cbor
use aiken/list
use aiken/merkle_patricia_forestry as mpt
use aiken/transaction.{InlineDatum, Input, Output}
use aiken/transaction/value
use common/assets.{parse_asset_id}
use common/mpf.{not_has}
use pz_items/types.{
  PzAssetProofs, PzFlags, PzItems, pz_items_asset_name, pz_items_asset_policy_id,
}

pub fn default_pz_flags() -> PzFlags {
  (0, 0)
}

pub fn parse_pz_flags(pz_flags: PzFlags) -> (Bool, Bool) {
  let (nsfw, trial) = pz_flags
  let nsfw_bool =
    when nsfw is {
      0 -> False
      1 -> True
      _ -> fail @"invalid nsfw flag"
    }
  let trial_bool =
    when trial is {
      0 -> False
      1 -> True
      _ -> fail @"invalid trial flag"
    }
  (nsfw_bool, trial_bool)
}

pub fn make_pz_flags(nsfw_bool: Bool, trial_bool: Bool) -> PzFlags {
  let nsfw =
    when nsfw_bool is {
      True -> 1
      False -> 0
    }
  let trial =
    when trial_bool is {
      True -> 1
      False -> 0
    }
  (nsfw, trial)
}

pub fn combine_two_pz_flags(pz_flags_1: PzFlags, pz_flags_2: PzFlags) -> PzFlags {
  let (nsfw_1, trial_1) = parse_pz_flags(pz_flags_1)
  let (nsfw_2, trial_2) = parse_pz_flags(pz_flags_2)
  make_pz_flags(nsfw_1 || nsfw_2, trial_1 || trial_2)
}

pub fn combine_policy_id_pz_flags_and_asset_id_pz_flags(
  policy_id_pz_flags: PzFlags,
  asset_id_pz_flags_opt: Option<PzFlags>,
) -> PzFlags {
  let (policy_id_nsfw_bool, policy_id_trial_bool) =
    parse_pz_flags(policy_id_pz_flags)

  when asset_id_pz_flags_opt is {
    Some(asset_id_pz_flags) -> {
      let (asset_id_nsfw_bool, asset_id_trial_bool) =
        parse_pz_flags(asset_id_pz_flags)
      make_pz_flags(
        policy_id_nsfw_bool || asset_id_nsfw_bool,
        policy_id_trial_bool || asset_id_trial_bool,
      )
    }
    None -> make_pz_flags(policy_id_nsfw_bool, policy_id_trial_bool)
  }
}

/// Find PzItems from reference inputs.
/// input's output value must have `pz_items_asset`.
///
pub fn find_pz_items(reference_inputs: List<Input>) -> PzItems {
  let pz_items_input_opt =
    list.find(
      reference_inputs,
      fn(i) {
        value.quantity_of(
          i.output.value,
          pz_items_asset_policy_id,
          pz_items_asset_name,
        ) == 1
      },
    )
  expect Some(pz_items_input) = pz_items_input_opt
  let Input { output: Output { datum, .. }, .. } = pz_items_input

  // parse PzItems as InlineDatum
  expect InlineDatum(inline_datum) = datum
  expect pz_items: PzItems = inline_datum
  pz_items
}

/// get Pz Asset's Pz Flags
/// Asset's Policy Id must be in Policies MPT with inclusing Proof
/// Asset's Id can be in Beta Assets MPT or NOT
/// if not, then need to proof non-membership proof
///
pub fn get_pz_asset_flags(
  asset_id: ByteArray,
  policies_mpt: mpt.MerklePatriciaForestry,
  beta_assets_mpt: mpt.MerklePatriciaForestry,
  pz_asset_proofs: PzAssetProofs,
) -> PzFlags {
  let (policy_id, _) = parse_asset_id(asset_id)

  let (policy_id_pz_flags_proof, asset_id_pz_flags_proof) = pz_asset_proofs
  let (policy_id_pz_flags, policy_id_mpt_proof) = policy_id_pz_flags_proof
  let (asset_id_pz_flags_opt, asset_id_mpt_proof) = asset_id_pz_flags_proof

  // check if asset's policy id is in Policies MPT
  let policy_id_pz_flags_cbor = cbor.serialise(policy_id_pz_flags)
  let policy_id_approved =
    mpt.has(
      policies_mpt,
      policy_id,
      policy_id_pz_flags_cbor,
      policy_id_mpt_proof,
    )
  expect policy_id_approved

  // check if asset's id is in Beta Assets MPT or NOT
  let asset_id_approved =
    when asset_id_pz_flags_opt is {
      Some(asset_id_pz_flags) -> {
        // prove asset id is in Beta Assets MPT
        let asset_id_pz_flags_cbor = cbor.serialise(asset_id_pz_flags)
        let asset_id_in_beta_assets_mpt =
          mpt.has(
            beta_assets_mpt,
            asset_id,
            asset_id_pz_flags_cbor,
            asset_id_mpt_proof,
          )
        expect asset_id_in_beta_assets_mpt

        True
      }
      None -> {
        // prove asset id is not in Beta Assets MPT
        let asset_id_not_in_beta_assets_mpt =
          not_has(beta_assets_mpt, asset_id, asset_id_mpt_proof)
        expect asset_id_not_in_beta_assets_mpt

        True
      }
    }
  expect asset_id_approved

  combine_policy_id_pz_flags_and_asset_id_pz_flags(
    policy_id_pz_flags,
    asset_id_pz_flags_opt,
  )
}

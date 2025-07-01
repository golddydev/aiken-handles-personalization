use aiken/merkle_patricia_forestry as mpt

// redeemer
pub type Indexes {
  pz_settings_index: Int,
  bg_approvers_index: Int,
  pfp_approvers_index: Int,
  bg_datum_index: Int,
  pfp_datum_index: Int,
}

// Approver Proofs
// *_policy_id_proof: MPT proof for valid * policy id
// *_policy_id_proof_value: Value of *_policy id in the MPT,
// either "" or root hash of MPT of *_asset names
// When empty string, means there is no MPT for asset names
// *_flags: Flags for trial | nsfw (when 1: True, 0: False)
// *_asset_name_proof: MPT proof for trial | nsfw *_asset name
//
pub type ApproverProofs {
  // bg
  bg_policy_id_proof_opt: Option<mpt.Proof>,
  bg_policy_id_proof_value: ByteArray,
  bg_flags: (Int, Int),
  bg_asset_name_proof_opt: Option<mpt.Proof>,
  // pfp
  pfp_policy_id_proof_opt: Option<mpt.Proof>,
  pfp_policy_id_proof_value: ByteArray,
  pfp_flags: (Int, Int),
  pfp_asset_name_proof_opt: Option<mpt.Proof>,
}

pub type Redeemer {
  indexes: Indexes,
  approver_proofs: ApproverProofs,
}

/// The generic CIP68 metadata type as defined in the CIP at
/// https://cips.cardano.org/cips/cip68/.
pub type CIP68Datum {
  metadata: Pairs<Data, Data>,
  version: Int,
  extra: Data,
}

// struct PzSettings {
//     treasury_fee: Int // 1st
//     treasury_cred: ByteArray // 2nd
//     pz_min_fee: Int // 3rd
//     pz_providers: Map[ByteArray]ByteArray // 4th
//     valid_contracts: []ByteArray // 5th
//     admin_creds: []ByteArray // 6th
//     settings_cred: ByteArray // 7th
//     grace_period: Int // 8th
//     subhandle_share_percent: Int // 9th
// }
pub type PZSettings =
  (
    Int,
    ByteArray,
    Int,
    Pairs<ByteArray, ByteArray>,
    List<ByteArray>,
    List<ByteArray>,
    ByteArray,
    Int,
    Int,
  )

use aiken/transaction/value.{AssetName, PolicyId}

pub const pz_approved_policies_asset_policy_id: PolicyId =
  #"f0ff48bbb7bbe9d59a40f1ce90e9e9d0ff5002ec48f232b49ca0fb9a"

/// 222 "pz_policies"
pub const pz_approved_policies_asset_name: AssetName =
  #"000de140707a5f706f6c6963696573"

pub type PzApprovedPolicies {
  mpt_root_hash: ByteArray,
}

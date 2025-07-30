use aiken/merkle_patricia_forestry as mpt
use aiken/transaction/value.{AssetName, PolicyId}

pub const pz_items_asset_policy_id: PolicyId =
  #"f0ff48bbb7bbe9d59a40f1ce90e9e9d0ff5002ec48f232b49ca0fb9a"

// 222 "pz_items"
pub const pz_items_asset_name: AssetName = #"000de140707a5f706f6c6963696573"

pub type PzItems {
  // approved policy ids for background and pfp
  policies: ByteArray,
  // beta assets ids (for trial or nsfw)
  beta_assets: ByteArray,
}

// trial, nsfw
// 0: false, 1: true, otherwise: invalid
pub type PzFlags =
  (Int, Int)

// pz flags and merkle trie proof
// this proof is inclusion proof.
pub type PolicyIdPzFlagsProof =
  (PzFlags, mpt.Proof)

// pz flags and merkle trie proof
// when pz flags are None, 
// it means to prove Non-membership of asset id.
pub type AssetIdPzFlagsProof =
  (Option<PzFlags>, mpt.Proof)

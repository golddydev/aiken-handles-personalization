use aiken/merkle_patricia_forestry as mpt

// nsfw, trial
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

// proof for policy id
// proof for asset id.
//
pub type PzAssetProofs =
  (PolicyIdPzFlagsProof, AssetIdPzFlagsProof)

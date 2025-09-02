import { MPTProof } from "./mpt.js";

interface PzItems {
  // MPT of approved policy ids for background and pfp
  policies: string;
  // MPT of beta assets ids (for nsfw and trial)
  beta_assets: string;
}

// nsfw, trial
// 0: false, 1: true, otherwise: invalid
interface PzFlags {
  nsfw: number;
  trial: number;
}

// pz flags and merkle trie proof
// this proof is inclusion proof.
interface PolicyIdPzFlagsProof {
  pzFlags: PzFlags;
  mptProof: MPTProof;
}

// pz flags and merkle trie proof
// when pz flags are None,
// it means to prove Non-membership of asset id.
interface AssetIdPzFlagsProof {
  pzFlags: PzFlags | null;
  mptProof: MPTProof;
}

// proof for policy id
// proof for asset id.
//
interface PzAssetProofs {
  policyIdPzFlagsProof: PolicyIdPzFlagsProof;
  assetIdPzFlagsProof: AssetIdPzFlagsProof;
}

export {
  AssetIdPzFlagsProof,
  PolicyIdPzFlagsProof,
  PzAssetProofs,
  PzFlags,
  PzItems,
};

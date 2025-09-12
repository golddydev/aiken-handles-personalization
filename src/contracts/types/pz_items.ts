import { ByteString, ConStr0 } from "@meshsdk/core";

import { MPTProof } from "./mpt.js";

export interface PzItems {
  // MPT of approved policy ids for background and pfp
  policies: string;
  // MPT of beta assets ids (for nsfw and trial)
  beta_assets: string;
}

export type PzItemsPlutusType = ConStr0<[ByteString, ByteString]>;

// nsfw, trial
// 0: false, 1: true, otherwise: invalid
export interface PzFlags {
  nsfw: number;
  trial: number;
}

// pz flags and merkle trie proof
// this proof is inclusion proof.
export interface PolicyIdPzFlagsProof {
  pzFlags: PzFlags;
  mptProof: MPTProof;
}

// pz flags and merkle trie proof
// when pz flags are None,
// it means to prove Non-membership of asset id.
export interface AssetIdPzFlagsProof {
  pzFlags: PzFlags | undefined;
  mptProof: MPTProof;
}

// proof for policy id
// proof for asset id.
//
export interface PzAssetProofs {
  policyIdPzFlagsProof: PolicyIdPzFlagsProof;
  assetIdPzFlagsProof: AssetIdPzFlagsProof;
}

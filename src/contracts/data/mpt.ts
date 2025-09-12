import { Data, mConStr0, mConStr1, mConStr2 } from "@meshsdk/core";

import { MPTProof, MPTProofStep, Neighbor } from "../types/index.js";

export const mMPTProof = (proof: MPTProof): Data => proof.map(mMPTProofStep);

export const mMPTProofStep = (proofStep: MPTProofStep): Data => {
  if (proofStep.type == "branch") {
    return mConStr0([proofStep.skip, proofStep.neighbors]);
  } else if (proofStep.type == "fork") {
    return mConStr1([proofStep.skip, mNeighbor(proofStep.neighbor)]);
  } else {
    return mConStr2([proofStep.skip, proofStep.key, proofStep.value]);
  }
};

export const mNeighbor = (neighbor: Neighbor): Data =>
  mConStr0([neighbor.nibble, neighbor.prefix, neighbor.root]);

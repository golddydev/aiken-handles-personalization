import { Data, mOption } from "@meshsdk/core";

import { PzAssetsProofs } from "../types/index.js";
import { mPzAssetProofs } from "./pz_items.js";

export const mPzAssetsProofs = (pzAssetsProofs: PzAssetsProofs): Data => {
  const { bgAssetProofs, pfpAssetProofs } = pzAssetsProofs;
  return [
    mOption(bgAssetProofs ? mPzAssetProofs(bgAssetProofs) : undefined),
    mOption(pfpAssetProofs ? mPzAssetProofs(pfpAssetProofs) : undefined),
  ];
};

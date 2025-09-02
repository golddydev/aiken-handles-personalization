import { makeListData, UplcData } from "@helios-lang/uplc";

import { PzAssetsProofs } from "../types/index.js";
import { makeOptionData } from "./common.js";
import { buildPzAssetProofsData } from "./pz_items.js";

const buildPzAssetsProofsData = (pzAssetsProofs: PzAssetsProofs): UplcData => {
  const { bgAssetProofs, pfpAssetProofs } = pzAssetsProofs;
  return makeListData([
    makeOptionData(bgAssetProofs, buildPzAssetProofsData),
    makeOptionData(pfpAssetProofs, buildPzAssetProofsData),
  ]);
};

export { buildPzAssetsProofsData };

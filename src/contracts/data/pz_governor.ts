import { AssetClass } from "@helios-lang/ledger";
import { makeConstrData, makeIntData, UplcData } from "@helios-lang/uplc";

import { PzIndexes } from "../types/index.js";
import { buildAssetClassData } from "./common.js";

const buildPzIndexesData = (pzIndexes: PzIndexes): UplcData => {
  const {
    treasury_output_index,
    provider_fee_output_index,
    shared_fee_output_index,
  } = pzIndexes;
  return makeConstrData(0, [
    makeIntData(treasury_output_index),
    makeIntData(provider_fee_output_index),
    makeIntData(shared_fee_output_index),
  ]);
};

const buildPzGovernorWithdrawPersonalizeRedeemer = (
  assetClass: AssetClass,
  pzIndexes: PzIndexes
) => {
  return makeConstrData(0, [
    buildAssetClassData(assetClass),
    buildPzIndexesData(pzIndexes),
  ]);
};

const buildPzGovernorWithdrawResetRedeemer = () => {
  return makeConstrData(1, []);
};

const buildPzGovernorWithdrawRevokeRedeemer = () => {
  return makeConstrData(2, []);
};

export {
  buildPzGovernorWithdrawPersonalizeRedeemer,
  buildPzGovernorWithdrawResetRedeemer,
  buildPzGovernorWithdrawRevokeRedeemer,
};

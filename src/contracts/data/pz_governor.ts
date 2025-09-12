import { Data, mAssetClass, mConStr0, mConStr1, mConStr2 } from "@meshsdk/core";

import { PzIndexes } from "../types/index.js";

export const mPzIndexes = (pzIndexes: PzIndexes): Data => {
  const {
    treasury_output_index,
    provider_fee_output_index,
    shared_fee_output_index,
  } = pzIndexes;
  return mConStr0([
    treasury_output_index,
    provider_fee_output_index,
    shared_fee_output_index,
  ]);
};

export const mPzGovernorWithdrawPersonalizeRedeemer = (
  policyId: string,
  tokenName: string,
  pzIndexes: PzIndexes
) => {
  return mConStr0([mAssetClass(policyId, tokenName), mPzIndexes(pzIndexes)]);
};

export const mPzGovernorWithdrawResetRedeemer = () => {
  return mConStr1([]);
};

export const mPzGovernorWithdrawRevokeRedeemer = () => {
  return mConStr2([]);
};

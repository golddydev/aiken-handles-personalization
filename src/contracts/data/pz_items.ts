import { Data, deserializeDatum, mConStr0, mOption } from "@meshsdk/core";

import { invariant } from "../../helpers/index.js";
import { expectByteString, expectConStr } from "../schemas/index.js";
import {
  AssetIdPzFlagsProof,
  PolicyIdPzFlagsProof,
  PzAssetProofs,
  PzFlags,
  PzItems,
  PzItemsPlutusType,
} from "../types/index.js";
import { mMPTProof } from "./mpt.js";

export const mPzItems = (pzItems: PzItems): Data => {
  const { policies, beta_assets } = pzItems;
  return mConStr0([policies, beta_assets]);
};

export const deserializePzItemsDatum = (
  datumCbor: string | undefined
): PzItems => {
  invariant(!!datumCbor, "Settings must be inline datum");
  const pzItemsPlutus = deserializeDatum<PzItemsPlutusType>(datumCbor);
  const pzItemsConstrData = expectConStr(pzItemsPlutus, 0, 2);

  const policies = expectByteString(
    pzItemsConstrData.fields[0],
    "policies must be ByteString"
  ).bytes;

  const beta_assets = expectByteString(
    pzItemsConstrData.fields[1],
    "beta_assets must be ByteString"
  ).bytes;

  return { policies, beta_assets };
};

export const mPzFlags = (pzFlags: PzFlags): Data => {
  const { nsfw, trial } = pzFlags;
  return [nsfw, trial];
};

export const mPolicyIdPzFlagsProof = (
  policyIdPzFlagsProof: PolicyIdPzFlagsProof
): Data => {
  const { pzFlags, mptProof } = policyIdPzFlagsProof;
  return [mPzFlags(pzFlags), mMPTProof(mptProof)];
};

export const mAssetIdPzFlagsProof = (
  assetIdPzFlagsProof: AssetIdPzFlagsProof
): Data => {
  const { pzFlags, mptProof } = assetIdPzFlagsProof;
  return [
    mOption(pzFlags ? mPzFlags(pzFlags) : undefined),
    mMPTProof(mptProof),
  ];
};

export const mPzAssetProofs = (pzAssetProofs: PzAssetProofs): Data => {
  const { policyIdPzFlagsProof, assetIdPzFlagsProof } = pzAssetProofs;
  return [
    mPolicyIdPzFlagsProof(policyIdPzFlagsProof),
    mAssetIdPzFlagsProof(assetIdPzFlagsProof),
  ];
};

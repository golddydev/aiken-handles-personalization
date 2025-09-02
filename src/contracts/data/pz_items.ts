import { TxOutputDatum } from "@helios-lang/ledger";
import {
  expectByteArrayData,
  expectConstrData,
  makeByteArrayData,
  makeConstrData,
  makeIntData,
  makeListData,
  UplcData,
} from "@helios-lang/uplc";

import { invariant } from "../../helpers/index.js";
import {
  AssetIdPzFlagsProof,
  PolicyIdPzFlagsProof,
  PzAssetProofs,
  PzFlags,
  PzItems,
} from "../types/index.js";
import { makeOptionData } from "./common.js";
import { buildMPTProofData } from "./mpt.js";

const buildPzItemsData = (pzItems: PzItems): UplcData => {
  const { policies, beta_assets } = pzItems;

  return makeConstrData(0, [
    makeByteArrayData(policies),
    makeByteArrayData(beta_assets),
  ]);
};

const decodePzItemsDatum = (datum: TxOutputDatum | undefined): PzItems => {
  invariant(
    datum?.kind == "InlineTxOutputDatum",
    "Minting Data Datum must be inline datum"
  );
  const datumData = datum.data;
  const pzItemsConstrData = expectConstrData(datumData, 0, 2);

  const policies = expectByteArrayData(
    pzItemsConstrData.fields[0],
    "policies must be ByteArray"
  ).toHex();

  const beta_assets = expectByteArrayData(
    pzItemsConstrData.fields[1],
    "beta_assets must be ByteArray"
  ).toHex();

  return { policies, beta_assets };
};

const buildPzFlagsData = (pzFlags: PzFlags): UplcData => {
  const { nsfw, trial } = pzFlags;
  return makeListData([makeIntData(nsfw), makeIntData(trial)]);
};

const buildPolicyIdPzFlagsProofData = (
  policyIdPzFlagsProof: PolicyIdPzFlagsProof
): UplcData => {
  const { pzFlags, mptProof } = policyIdPzFlagsProof;
  return makeListData([buildPzFlagsData(pzFlags), buildMPTProofData(mptProof)]);
};

const buildAssetIdPzFlagsProofData = (
  assetIdPzFlagsProof: AssetIdPzFlagsProof
): UplcData => {
  const { pzFlags, mptProof } = assetIdPzFlagsProof;
  return makeListData([
    makeOptionData(pzFlags, buildPzFlagsData),
    buildMPTProofData(mptProof),
  ]);
};

const buildPzAssetProofsData = (pzAssetProofs: PzAssetProofs): UplcData => {
  const { policyIdPzFlagsProof, assetIdPzFlagsProof } = pzAssetProofs;
  return makeListData([
    buildPolicyIdPzFlagsProofData(policyIdPzFlagsProof),
    buildAssetIdPzFlagsProofData(assetIdPzFlagsProof),
  ]);
};

export {
  buildAssetIdPzFlagsProofData,
  buildPolicyIdPzFlagsProofData,
  buildPzAssetProofsData,
  buildPzFlagsData,
  buildPzItemsData,
  decodePzItemsDatum,
};

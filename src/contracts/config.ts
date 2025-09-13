import {
  resolveScriptHash,
  serializePlutusScript,
  serializeRewardAddress,
} from "@meshsdk/core";

import { getNetworkId } from "../helpers/index.js";
import {
  getBgConstraintsWithdrawScript,
  getPzAssetsWithdrawScript,
  getPzGovernorWithdrawScript,
  getPzProxySpendScript,
} from "./validators.js";

export interface BuildScriptsParams {
  isMainnet: boolean;
}

/**
 * @description Build Scripts for Handle's Personalization
 * @param {BuildScriptsParams} params
 * @returns All Scripts
 */
export const buildScripts = (params: BuildScriptsParams) => {
  const { isMainnet } = params;

  // "pz_proxy.spend"
  const pzProxySpendScript = getPzProxySpendScript();
  const pzProxySpendScriptHash = resolveScriptHash(
    pzProxySpendScript.optimized.code,
    pzProxySpendScript.optimized.version
  );
  const pzProxySpendScriptAddress = serializePlutusScript(
    pzProxySpendScript.optimized,
    undefined,
    getNetworkId(isMainnet)
  ).address;

  // "pz_governor.withdraw"
  const pzGovernorWithdrawScript = getPzGovernorWithdrawScript();
  const pzGovernorScriptHash = resolveScriptHash(
    pzGovernorWithdrawScript.optimized.code,
    pzGovernorWithdrawScript.optimized.version
  );
  const pzGovernorRewardAddress = serializeRewardAddress(
    pzGovernorScriptHash,
    true,
    getNetworkId(isMainnet)
  );

  // "pz_assets.withdraw"
  const pzAssetsWithdrawScript = getPzAssetsWithdrawScript();
  const pzAssetsScriptHash = resolveScriptHash(
    pzAssetsWithdrawScript.optimized.code,
    pzAssetsWithdrawScript.optimized.version
  );
  const pzAssetsRewardAddress = serializeRewardAddress(
    pzAssetsScriptHash,
    true,
    getNetworkId(isMainnet)
  );

  // "bg_constraints.withdraw"
  const bgConstraintsWithdrawScript = getBgConstraintsWithdrawScript();
  const bgConstraintsScriptHash = resolveScriptHash(
    bgConstraintsWithdrawScript.optimized.code,
    bgConstraintsWithdrawScript.optimized.version
  );
  const bgConstraintsRewardAddress = serializeRewardAddress(
    bgConstraintsScriptHash,
    true,
    getNetworkId(isMainnet)
  );

  return {
    pzProxySpend: {
      pzProxySpendScript,
      pzProxySpendScriptHash,
      pzProxySpendScriptAddress,
    },
    pzGovernor: {
      pzGovernorWithdrawScript,
      pzGovernorScriptHash,
      pzGovernorRewardAddress,
    },
    pzAssets: {
      pzAssetsWithdrawScript,
      pzAssetsScriptHash,
      pzAssetsRewardAddress,
    },
    bgConstraints: {
      bgConstraintsWithdrawScript,
      bgConstraintsScriptHash,
      bgConstraintsRewardAddress,
    },
  };
};

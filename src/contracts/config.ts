import {
  makeAddress,
  makeRegistrationDCert,
  makeStakingAddress,
  makeStakingValidatorHash,
  makeValidatorHash,
} from "@helios-lang/ledger";

import {
  getBgConstraintsWithdrawUplcProgram,
  getPzAssetsWithdrawUplcProgram,
  getPzGovernorWithdrawUplcProgram,
  getPzProxySpendUplcProgram,
} from "./validators.js";

interface BuildContractsParams {
  isMainnet: boolean;
}

/**
 * @description Build Contracts for De-Mi from config
 * @param {BuildContractsParams} params
 * @returns All Contracts
 */
const buildContracts = (params: BuildContractsParams) => {
  const { isMainnet } = params;

  // "pz_proxy.spend"
  const pzProxySpendUplcProgram = getPzProxySpendUplcProgram();
  const pzProxySpendValidatorHash = makeValidatorHash(
    pzProxySpendUplcProgram.hash()
  );
  const pzProxySpendValidatorAddress = makeAddress(
    isMainnet,
    pzProxySpendValidatorHash
  );

  // "pz_governor.withdraw"
  const pzGovernorWithdrawUplcProgram = getPzGovernorWithdrawUplcProgram();
  const pzGovernorValidatorHash = makeValidatorHash(
    pzGovernorWithdrawUplcProgram.hash()
  );
  const pzGovernorStakingAddress = makeStakingAddress(
    isMainnet,
    makeStakingValidatorHash(pzGovernorWithdrawUplcProgram.hash())
  );
  const pzGovernorRegistrationDCert = makeRegistrationDCert(
    pzGovernorStakingAddress.stakingCredential
  );

  // "pz_assets.withdraw"
  const pzAssetsWithdrawUplcProgram = getPzAssetsWithdrawUplcProgram();
  const pzAssetsValidatorHash = makeValidatorHash(
    pzAssetsWithdrawUplcProgram.hash()
  );
  const pzAssetsStakingAddress = makeStakingAddress(
    isMainnet,
    makeStakingValidatorHash(pzAssetsWithdrawUplcProgram.hash())
  );
  const pzAssetsRegistrationDCert = makeRegistrationDCert(
    pzAssetsStakingAddress.stakingCredential
  );

  // "bg_constraints.withdraw"
  const bgConstraintsWithdrawUplcProgram =
    getBgConstraintsWithdrawUplcProgram();
  const bgConstraintsValidatorHash = makeValidatorHash(
    bgConstraintsWithdrawUplcProgram.hash()
  );
  const bgConstraintsStakingAddress = makeStakingAddress(
    isMainnet,
    makeStakingValidatorHash(bgConstraintsWithdrawUplcProgram.hash())
  );
  const bgConstraintsRegistrationDCert = makeRegistrationDCert(
    bgConstraintsStakingAddress.stakingCredential
  );

  return {
    pzProxySpend: {
      pzProxySpendUplcProgram,
      pzProxySpendValidatorHash,
      pzProxySpendValidatorAddress,
    },
    pzGovernor: {
      pzGovernorWithdrawUplcProgram,
      pzGovernorValidatorHash,
      pzGovernorStakingAddress,
      pzGovernorRegistrationDCert,
    },
    pzAssets: {
      pzAssetsWithdrawUplcProgram,
      pzAssetsValidatorHash,
      pzAssetsStakingAddress,
      pzAssetsRegistrationDCert,
    },
    bgConstraints: {
      bgConstraintsWithdrawUplcProgram,
      bgConstraintsValidatorHash,
      bgConstraintsStakingAddress,
      bgConstraintsRegistrationDCert,
    },
  };
};

export type { BuildContractsParams };
export { buildContracts };

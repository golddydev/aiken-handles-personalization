import { decodeUplcProgramV2FromCbor, UplcProgramV2 } from "@helios-lang/uplc";

import { CONTRACT_NAME } from "../constants/index.js";
import { invariant } from "../helpers/index.js";
import optimizedBlueprint from "./optimized-blueprint.js";
import unOptimizedBlueprint from "./unoptimized-blueprint.js";

const getPzProxySpendUplcProgram = (): UplcProgramV2 => {
  const optimizedFoundValidator = optimizedBlueprint.validators.find(
    (validator) => validator.title == CONTRACT_NAME.PZ_PROXY_SPEND
  );
  const unOptimizedFoundValidator = unOptimizedBlueprint.validators.find(
    (validator) => validator.title == CONTRACT_NAME.PZ_PROXY_SPEND
  );
  invariant(
    !!optimizedFoundValidator && !!unOptimizedFoundValidator,
    "Pz Proxy Spend Validator not found"
  );
  return decodeUplcProgramV2FromCbor(
    optimizedFoundValidator.compiledCode
  ).withAlt(
    decodeUplcProgramV2FromCbor(unOptimizedFoundValidator.compiledCode)
  );
};

const getPzGovernorWithdrawUplcProgram = (): UplcProgramV2 => {
  const optimizedFoundValidator = optimizedBlueprint.validators.find(
    (validator) => validator.title == CONTRACT_NAME.PZ_GOVERNOR_WITHDRAW
  );
  const unOptimizedFoundValidator = unOptimizedBlueprint.validators.find(
    (validator) => validator.title == CONTRACT_NAME.PZ_GOVERNOR_WITHDRAW
  );
  invariant(
    !!optimizedFoundValidator && unOptimizedFoundValidator,
    "Pz Governor Withdrawal Validator not found"
  );
  return decodeUplcProgramV2FromCbor(
    optimizedFoundValidator.compiledCode
  ).withAlt(
    decodeUplcProgramV2FromCbor(unOptimizedFoundValidator.compiledCode)
  );
};

const getPzAssetsWithdrawUplcProgram = (): UplcProgramV2 => {
  const optimizedFoundValidator = optimizedBlueprint.validators.find(
    (validator) => validator.title == CONTRACT_NAME.PZ_ASSETS_WITHDRAW
  );
  const unOptimizedFoundValidator = unOptimizedBlueprint.validators.find(
    (validator) => validator.title == CONTRACT_NAME.PZ_ASSETS_WITHDRAW
  );
  invariant(
    !!optimizedFoundValidator && !!unOptimizedFoundValidator,
    "Pz Assets Withdrawal Validator not found"
  );
  return decodeUplcProgramV2FromCbor(
    optimizedFoundValidator.compiledCode
  ).withAlt(
    decodeUplcProgramV2FromCbor(unOptimizedFoundValidator.compiledCode)
  );
};

const getBgConstraintsWithdrawUplcProgram = (): UplcProgramV2 => {
  const optimizedFoundValidator = optimizedBlueprint.validators.find(
    (validator) => validator.title == CONTRACT_NAME.BG_CONSTRAINTS_WITHDRAW
  );
  const unOptimizedFoundValidator = unOptimizedBlueprint.validators.find(
    (validator) => validator.title == CONTRACT_NAME.BG_CONSTRAINTS_WITHDRAW
  );
  invariant(
    !!optimizedFoundValidator && !!unOptimizedFoundValidator,
    "Bg Constraints Withdrawal Validator not found"
  );
  return decodeUplcProgramV2FromCbor(
    optimizedFoundValidator.compiledCode
  ).withAlt(
    decodeUplcProgramV2FromCbor(unOptimizedFoundValidator.compiledCode)
  );
};

export {
  getBgConstraintsWithdrawUplcProgram,
  getPzAssetsWithdrawUplcProgram,
  getPzGovernorWithdrawUplcProgram,
  getPzProxySpendUplcProgram,
};

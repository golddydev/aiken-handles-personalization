import { applyCborEncoding, PlutusScript } from "@meshsdk/core";

import { CONTRACT_NAME } from "../constants/index.js";
import { invariant } from "../helpers/index.js";
import optimizedBlueprint from "./optimized-blueprint.js";
import unOptimizedBlueprint from "./unoptimized-blueprint.js";

export const getPzProxySpendScript = (): {
  optimized: PlutusScript;
  unoptimized: PlutusScript;
} => {
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
  return {
    optimized: {
      code: applyCborEncoding(optimizedFoundValidator.compiledCode),
      version: "V2",
    },
    unoptimized: {
      code: applyCborEncoding(unOptimizedFoundValidator.compiledCode),
      version: "V2",
    },
  };
};

export const getPzGovernorWithdrawScript = (): {
  optimized: PlutusScript;
  unoptimized: PlutusScript;
} => {
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
  return {
    optimized: {
      code: applyCborEncoding(optimizedFoundValidator.compiledCode),
      version: "V2",
    },
    unoptimized: {
      code: applyCborEncoding(unOptimizedFoundValidator.compiledCode),
      version: "V2",
    },
  };
};

export const getPzAssetsWithdrawScript = (): {
  optimized: PlutusScript;
  unoptimized: PlutusScript;
} => {
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
  return {
    optimized: {
      code: applyCborEncoding(optimizedFoundValidator.compiledCode),
      version: "V2",
    },
    unoptimized: {
      code: applyCborEncoding(unOptimizedFoundValidator.compiledCode),
      version: "V2",
    },
  };
};

export const getBgConstraintsWithdrawScript = (): {
  optimized: PlutusScript;
  unoptimized: PlutusScript;
} => {
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
  return {
    optimized: {
      code: applyCborEncoding(optimizedFoundValidator.compiledCode),
      version: "V2",
    },
    unoptimized: {
      code: applyCborEncoding(unOptimizedFoundValidator.compiledCode),
      version: "V2",
    },
  };
};

import { Data, mAssetClass } from "@meshsdk/core";

import { DesignerSettings } from "../types/index.js";

export const mDesignerSettingsValue = (
  value: string | string[] | number | number[]
): Data => {
  if (Array.isArray(value)) {
    return value.map(mDesignerSettingsValue);
  } else if (typeof value === "number") {
    return value;
  } else if (typeof value === "string") {
    return value;
  } else {
    throw new Error(
      "Designer Settings value must be string | string[] | number | number[]"
    );
  }
};

export const mDesignerSettings = (designerSettings: DesignerSettings): Data =>
  Object.entries(designerSettings).map(([key, value]) => [
    key,
    mDesignerSettingsValue(value),
  ]);

export const mBgConstraintsWithdrawRedeemer = (
  policy_id: string,
  asset_name: string,
  designerSettings: DesignerSettings
): Data => [
  mAssetClass(policy_id, asset_name),
  mDesignerSettings(designerSettings),
];

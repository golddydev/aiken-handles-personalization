import { AssetClass } from "@helios-lang/ledger";
import {
  makeByteArrayData,
  makeIntData,
  makeListData,
  UplcData,
} from "@helios-lang/uplc";

import { DesignerSettings } from "../types/index.js";
import { buildAssetClassData } from "./common.js";

const buildDesignerSettingsValueData = (
  value: string | string[] | number | number[]
): UplcData => {
  if (Array.isArray(value)) {
    return makeListData(value.map(buildDesignerSettingsValueData));
  } else if (typeof value === "number") {
    return makeIntData(value);
  } else if (typeof value === "string") {
    return makeByteArrayData(value);
  } else {
    throw new Error(
      "Designer Settings value must be string | string[] | number | number[]"
    );
  }
};

const buildDesignerSettingsData = (
  designerSettings: DesignerSettings
): UplcData => {
  return makeListData(
    Object.entries(designerSettings).map(([key, value]) =>
      makeListData([
        makeByteArrayData(key),
        buildDesignerSettingsValueData(value),
      ])
    )
  );
};

const buildBgConstraintsWithdrawRedeemer = (
  assetClass: AssetClass,
  designerSettings: DesignerSettings
): UplcData => {
  return makeListData([
    buildAssetClassData(assetClass),
    buildDesignerSettingsData(designerSettings),
  ]);
};

export { buildBgConstraintsWithdrawRedeemer };

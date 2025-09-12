import { Data, deserializeDatum, mConStr0 } from "@meshsdk/core";

import { invariant } from "../../helpers/index.js";
import { expectByteString, expectConStr } from "../schemas/index.js";
import { Settings, SettingsPlutusType } from "../types/index.js";
import { expectSettingsV1, mSettingsV1 } from "./settings_v1.js";

export const mSettings = (settings: Settings): Data => {
  const { pz_governor, data } = settings;
  return mConStr0([pz_governor, mSettingsV1(data)]);
};

export const deserializeSettingsDatum = (
  datumCbor: string | undefined
): Settings => {
  invariant(!!datumCbor, "Settings must be inline datum");
  const settingsPlutus = deserializeDatum<SettingsPlutusType>(datumCbor);
  const settingsConstrData = expectConStr(settingsPlutus, 0, 2);

  // pz_governor
  const pz_governor = expectByteString(
    settingsConstrData.fields[0],
    "pz_governor must be ByteString"
  ).bytes;

  // data
  const data = expectSettingsV1(settingsConstrData.fields[1]);

  return {
    pz_governor,
    data,
  };
};

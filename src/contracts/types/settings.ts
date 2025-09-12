import { ByteString, ConStr0 } from "@meshsdk/core";

import { SettingsV1, SettingsV1PlutusType } from "./settings_v1.js";

export interface Settings {
  // pz_governor withdrawal script hash
  pz_governor: string;
  // settings v1 data
  data: SettingsV1;
}

export type SettingsPlutusType = ConStr0<
  [
    // pz_governor withdrawal script hash
    ByteString,
    // settings v1 data
    SettingsV1PlutusType
  ]
>;

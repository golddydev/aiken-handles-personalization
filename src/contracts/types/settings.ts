import { UplcData } from "@helios-lang/uplc";

interface Settings {
  pz_governor: string; // withdrawal script hash
  data: UplcData; // settings v1 data
}

export type { Settings };

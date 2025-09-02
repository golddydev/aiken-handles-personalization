import { AssetClass } from "@helios-lang/ledger";
import {
  makeByteArrayData,
  makeConstrData,
  makeListData,
  UplcData,
} from "@helios-lang/uplc";

const buildAssetClassData = (assetClass: AssetClass): UplcData => {
  return makeListData([
    makeByteArrayData(assetClass.mph.toHex()),
    makeByteArrayData(Buffer.from(assetClass.tokenName)),
  ]);
};

const makeOptionData = <T>(
  value: T | null | undefined,
  builder: (value: T) => UplcData
): UplcData => {
  if (!value) {
    return makeConstrData(1, []);
  }
  return makeConstrData(0, [builder(value)]);
};

export { buildAssetClassData, makeOptionData };

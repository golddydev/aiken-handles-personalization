import { TxInput } from "@meshsdk/core";
import { Err, Ok, Result } from "ts-res";

import {
  PZ_ITEMS_HANDLE_NAME,
  PZ_SETTINGS_HANDLE_NAME,
} from "../constants/index.js";
import {
  deserializePzItemsDatum,
  deserializeSettingsDatum,
  PzItems,
  Settings,
} from "../contracts/index.js";
import { convertError, fetchApi } from "../helpers/index.js";

interface HandleUTxOApiResponse {
  tx_id: string;
  index: number;
  lovelace: number;
  address: string;
  datum: string;
}

export const fetchSettings = async (): Promise<
  Result<
    {
      settings: Settings;
      settingsAssetTxInput: TxInput;
    },
    string
  >
> => {
  try {
    const settingsHandleUtxo = (await fetchApi(
      `handles/${PZ_SETTINGS_HANDLE_NAME}/utxo`
    ).then((res) => res.json())) as HandleUTxOApiResponse;

    const txHash = settingsHandleUtxo.tx_id;
    const outputIndex = Number(settingsHandleUtxo.index);
    if (!txHash || !outputIndex) {
      throw new Error("PZ Settings UTxO Invalid");
    }
    const txInput: TxInput = {
      txHash,
      outputIndex,
    };
    const settings = deserializeSettingsDatum(settingsHandleUtxo.datum);

    return Ok({
      settings,
      settingsAssetTxInput: txInput,
    });
  } catch (error) {
    return Err(convertError(error));
  }
};

export const fetchPzItems = async (): Promise<
  Result<{ pzItems: PzItems; pzItemsAssetTxInput: TxInput }, string>
> => {
  try {
    const pzItemsHandleUtxo = (await fetchApi(
      `handles/${PZ_ITEMS_HANDLE_NAME}/utxo`
    ).then((res) => res.json())) as HandleUTxOApiResponse;

    const txHash = pzItemsHandleUtxo.tx_id;
    const outputIndex = Number(pzItemsHandleUtxo.index);
    if (!txHash || !outputIndex) {
      throw new Error("PZ Settings UTxO Invalid");
    }
    const txInput: TxInput = {
      txHash,
      outputIndex,
    };
    const pzItems = deserializePzItemsDatum(pzItemsHandleUtxo.datum);

    return Ok({
      pzItems,
      pzItemsAssetTxInput: txInput,
    });
  } catch (error) {
    return Err(convertError(error));
  }
};

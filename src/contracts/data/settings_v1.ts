import {
  expectByteArrayData,
  expectConstrData,
  expectIntData,
  expectListData,
  makeByteArrayData,
  makeConstrData,
  makeIntData,
  makeListData,
  UplcData,
} from "@helios-lang/uplc";

import { SettingsV1 } from "../types/index.js";

const buildSettingsV1Data = (settings: SettingsV1): UplcData => {
  const {
    policy_ids,
    pz_script_hashes,
    pz_items_governor,
    bg_constraints_governor,
    settings_script_hash,
    provider_script_hashes,
    treasury_script_hash,
    admin_verification_key_hashes,
    treasury_fee,
    pz_min_fee,
    grace_period,
    subhandle_share_percent,
  } = settings;

  return makeConstrData(0, [
    makeListData(policy_ids.map(makeByteArrayData)),
    makeListData(pz_script_hashes.map(makeByteArrayData)),
    makeByteArrayData(pz_items_governor),
    makeByteArrayData(bg_constraints_governor),
    makeByteArrayData(settings_script_hash),
    makeListData(provider_script_hashes.map(makeByteArrayData)),
    makeByteArrayData(treasury_script_hash),
    makeListData(admin_verification_key_hashes.map(makeByteArrayData)),
    makeIntData(treasury_fee),
    makeIntData(pz_min_fee),
    makeIntData(grace_period),
    makeIntData(subhandle_share_percent),
  ]);
};

const decodeSettingsV1Data = (data: UplcData): SettingsV1 => {
  const settingsV1ConstrData = expectConstrData(data, 0, 12);

  // policy_ids
  const policy_ids = expectListData(
    settingsV1ConstrData.fields[0],
    "policy_ids must be List"
  ).items.map((item) =>
    expectByteArrayData(item, "policy_id must be ByteArray").toHex()
  );

  // pz_script_hashes
  const pz_script_hashes = expectListData(
    settingsV1ConstrData.fields[1],
    "pz_script_hashes must be List"
  ).items.map((item) =>
    expectByteArrayData(item, "pz_script_hash must be ByteArray").toHex()
  );

  // pz_items_governor
  const pz_items_governor = expectByteArrayData(
    settingsV1ConstrData.fields[2],
    "pz_items_governor must be ByteArray"
  ).toHex();

  // bg_constraints_governor
  const bg_constraints_governor = expectByteArrayData(
    settingsV1ConstrData.fields[3],
    "bg_constraints_governor must be ByteArray"
  ).toHex();

  // settings_script_hash
  const settings_script_hash = expectByteArrayData(
    settingsV1ConstrData.fields[4],
    "settings_script_hash must be ByteArray"
  ).toHex();

  // provider_script_hashes
  const provider_script_hashes = expectListData(
    settingsV1ConstrData.fields[5],
    "provider_script_hashes must be List"
  ).items.map((item) =>
    expectByteArrayData(item, "provider_script_hash must be ByteArray").toHex()
  );

  // treasury_script_hash
  const treasury_script_hash = expectByteArrayData(
    settingsV1ConstrData.fields[6],
    "treasury_script_hash must be ByteArray"
  ).toHex();

  // admin_verification_key_hashes
  const admin_verification_key_hashes = expectListData(
    settingsV1ConstrData.fields[7],
    "admin_verification_key_hashes must be List"
  ).items.map((item) =>
    expectByteArrayData(
      item,
      "admin_verification_key_hash must be ByteArray"
    ).toHex()
  );

  // treasury_fee
  const treasury_fee = expectIntData(
    settingsV1ConstrData.fields[8],
    "treasury_fee must be Int"
  ).value;

  // pz_min_fee
  const pz_min_fee = expectIntData(
    settingsV1ConstrData.fields[9],
    "pz_min_fee must be Int"
  ).value;

  // grace_period
  const grace_period = expectIntData(
    settingsV1ConstrData.fields[10],
    "grace_period must be Int"
  ).value;

  // subhandle_share_percent
  const subhandle_share_percent = expectIntData(
    settingsV1ConstrData.fields[11],
    "subhandle_share_percent must be Int"
  ).value;

  return {
    policy_ids,
    pz_script_hashes,
    pz_items_governor,
    bg_constraints_governor,
    settings_script_hash,
    provider_script_hashes,
    treasury_script_hash,
    admin_verification_key_hashes,
    treasury_fee,
    pz_min_fee,
    grace_period,
    subhandle_share_percent,
  };
};

export { buildSettingsV1Data, decodeSettingsV1Data };

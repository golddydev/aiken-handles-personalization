import { Data, mConStr0 } from "@meshsdk/core";

import {
  expectByteString,
  expectConStr,
  expectInteger,
  expectList,
} from "../schemas/index.js";
import { SettingsV1 } from "../types/index.js";

export const mSettingsV1 = (settings: SettingsV1): Data => {
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

  return mConStr0([
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
  ]);
};

// eslint-disable-next-line @typescript-eslint/no-explicit-any
export const expectSettingsV1 = (data: any): SettingsV1 => {
  const settingsV1ConstrData = expectConStr(
    data,
    0,
    12,
    "SettingsV1 must be ConStr0"
  );

  // policy_ids
  const policy_ids = expectList(
    settingsV1ConstrData.fields[0],
    "policy_ids must be List"
  ).list.map(
    (item) => expectByteString(item, "policy_id must be ByteString").bytes
  );

  // pz_script_hashes
  const pz_script_hashes = expectList(
    settingsV1ConstrData.fields[1],
    "pz_script_hashes must be List"
  ).list.map(
    (item) => expectByteString(item, "pz_script_hash must be ByteString").bytes
  );

  // pz_items_governor
  const pz_items_governor = expectByteString(
    settingsV1ConstrData.fields[2],
    "pz_items_governor must be ByteString"
  ).bytes;

  // bg_constraints_governor
  const bg_constraints_governor = expectByteString(
    settingsV1ConstrData.fields[3],
    "bg_constraints_governor must be ByteString"
  ).bytes;

  // settings_script_hash
  const settings_script_hash = expectByteString(
    settingsV1ConstrData.fields[4],
    "settings_script_hash must be ByteString"
  ).bytes;

  // provider_script_hashes
  const provider_script_hashes = expectList(
    settingsV1ConstrData.fields[5],
    "provider_script_hashes must be List"
  ).list.map(
    (item) =>
      expectByteString(item, "provider_script_hash must be ByteString").bytes
  );

  // treasury_script_hash
  const treasury_script_hash = expectByteString(
    settingsV1ConstrData.fields[6],
    "treasury_script_hash must be ByteString"
  ).bytes;

  // admin_verification_key_hashes
  const admin_verification_key_hashes = expectList(
    settingsV1ConstrData.fields[7],
    "admin_verification_key_hashes must be List"
  ).list.map(
    (item) =>
      expectByteString(item, "admin_verification_key_hash must be ByteString")
        .bytes
  );

  // treasury_fee
  const treasury_fee = BigInt(
    expectInteger(
      settingsV1ConstrData.fields[8],
      "treasury_fee must be Integer"
    ).int
  );

  // pz_min_fee
  const pz_min_fee = BigInt(
    expectInteger(settingsV1ConstrData.fields[9], "pz_min_fee must be Integer")
      .int
  );

  // grace_period
  const grace_period = BigInt(
    expectInteger(
      settingsV1ConstrData.fields[10],
      "grace_period must be Integer"
    ).int
  );

  // subhandle_share_percent
  const subhandle_share_percent = BigInt(
    expectInteger(
      settingsV1ConstrData.fields[11],
      "subhandle_share_percent must be Integer"
    ).int
  );

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

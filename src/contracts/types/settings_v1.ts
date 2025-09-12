import { ByteString, ConStr0, Integer, List } from "@meshsdk/core";

export interface SettingsV1 {
  // valid handle policy ids
  policy_ids: string[];
  // bg_constraints_governor script hash
  bg_constraints_governor: string;
  // pz_items_governor script hash
  pz_items_governor: string;
  // script hash where
  // all important assets are locked
  settings_script_hash: string;
  // valid personalization script hashes
  pz_script_hashes: string[];
  // personalization provider script hashes
  provider_script_hashes: string[];
  // treasury script hash
  treasury_script_hash: string;
  // admin verification key hashes
  admin_verification_key_hashes: string[];
  // treasury fee
  treasury_fee: bigint;
  // pz min fee
  pz_min_fee: bigint;
  // grace period
  grace_period: bigint;
  // subhandle share percent
  subhandle_share_percent: bigint;
}

export type SettingsV1PlutusType = ConStr0<
  [
    // valid handle policy ids
    List<ByteString>,
    // bg_constraints_governor script hash
    ByteString,
    // pz_items_governor script hash
    ByteString,
    // script hash where
    // all important assets are locked
    ByteString,
    // valid personalization script hashes
    List<ByteString>,
    // personalization provider script hashes
    List<ByteString>,
    // treasury script hash
    ByteString,
    // admin verification key hashes
    List<ByteString>,
    // treasury fee
    Integer,
    // pz min fee
    Integer,
    // grace period
    Integer,
    // subhandle share percent
    Integer
  ]
>;

use aiken/transaction/value.{PolicyId}
use common/hashes.{ScriptHash, VerificationKeyHash}

pub type PzSettingsV1 {
  // valid handle policy ids
  policy_ids: List<PolicyId>,
  // valid personalization script hashes
  pz_script_hashes: List<ScriptHash>,
  // pz_items_governor script hash
  pz_items_governor: ScriptHash,
  // bg_constraints_governor script hash
  bg_constraints_governor: ScriptHash,
  // script hash where 
  // all important assets are locked
  settings_script_hash: ScriptHash,
  // personalization provider script hashes
  provider_script_hashes: List<ScriptHash>,
  // treasury script hash
  treasury_script_hash: ScriptHash,
  // admin verification key hashes
  admin_verification_key_hashes: List<VerificationKeyHash>,
  // treasury fee
  treasury_fee: Int,
  // pz min fee
  pz_min_fee: Int,
  // grace period
  grace_period: Int,
  // subhandle share percent
  subhandle_share_percent: Int,
}

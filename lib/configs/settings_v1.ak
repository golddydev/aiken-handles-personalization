use common/hashes.{ScriptHash, VerificationKeyHash}

pub type PzSettingsV1 {
  settings_script_hash: ScriptHash,
  pz_script_hashes: List<ScriptHash>,
  provider_script_hashes: List<ScriptHash>,
  treasury_script_hash: ScriptHash,
  admin_verification_key_hashes: List<VerificationKeyHash>,
  treasury_fee: Int,
  pz_min_fee: Int,
  grace_period: Int,
  subhandle_share_percent: Int,
}

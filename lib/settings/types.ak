use aiken/transaction/value.{AssetName, PolicyId}
use common/hashes.{ScriptHash, VerificationKeyHash}

pub const pz_settings_asset_policy_id: PolicyId =
  #"f0ff48bbb7bbe9d59a40f1ce90e9e9d0ff5002ec48f232b49ca0fb9a"

/// 222 "pz_settings"
pub const pz_settings_asset_name: AssetName = #"000de140707a5f73657474696e6773"

pub type PzSettings {
  pz_governor: ScriptHash,
  data: PzSettingsV1,
}

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

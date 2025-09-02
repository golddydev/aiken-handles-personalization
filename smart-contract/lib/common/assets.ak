use aiken/bytearray
use aiken/transaction/value.{AssetName, PolicyId}

pub type AssetClass =
  (PolicyId, AssetName)

pub fn parse_asset_id(asset_id: ByteArray) -> AssetClass {
  expect bytearray.length(asset_id) > 28

  let policy_id: PolicyId = bytearray.take(asset_id, 28)
  let asset_name: AssetName = bytearray.drop(asset_id, 28)

  (policy_id, asset_name)
}
